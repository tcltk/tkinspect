#
# $Id$
#
# This software is copyright (C) 1995 by the Lawrence Berkeley Laboratory.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that: (1) source code distributions
# retain the above copyright notice and this paragraph in its entirety, (2)
# distributions including binary code include the above copyright notice and
# this paragraph in its entirety in the documentation or other materials
# provided with the distribution, and (3) all advertising materials mentioning
# features or use of this software display the following acknowledgement:
# ``This product includes software developed by the University of California,
# Lawrence Berkeley Laboratory and its contributors.'' Neither the name of
# the University nor the names of its contributors may be used to endorse
# or promote products derived from this software without specific prior
# written permission.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
# This code is based on Angel Li's (angel@flipper.rsmas.miami.edu) HTML
# rendering code.
#

proc tkhtml_set_render_hook {hook} {
    global tkhtml_priv
    set tkhtml_priv(render_hook) $hook
}

proc tkhtml_set_image_hook {hook} {
    global tkhtml_priv
    set tkhtml_priv(image_hook) $hook
}

proc tkhtml_render {w html} {
    global tkhtml_priv tkhtml_entity
    $w config -state normal
    $w delete 1.0 end
    tkhtml_setup $w
    set tkhtml_priv(continue_rendering) 1
    tkhtml_set_tag
    while {$tkhtml_priv(continue_rendering)} {
	# normal state
	while {[set len [string length $html]]} {
	    # look for text up to the next <> element
	    if [regexp -indices "^\[^<\]+" $html match] {
		set text [string range $html 0 [lindex $match 1]]
		tkhtml_append_text $text
		set html \
		    [string range $html [expr [lindex $match 1]+1] end]
	    }
	    # we're either at a <>, or at the eot
	    if [regexp -indices "^<(\[^>\]+)>" $html match entity] {
		set entity [string range $html [lindex $entity 0] \
			    [lindex $entity 1]]
		set cmd [string tolower [lindex $entity 0]]
		if {[info exists tkhtml_entity($cmd)]} {
		    tkhtml_do $cmd [lrange $entity 1 end]
		}
		set html \
		    [string range $html [expr [lindex $match 1]+1] end]
	    }
	    if [info exists tkhtml_priv(render_hook)] {
		eval $tkhtml_priv(render_hook) $len
	    }
	    if $tkhtml_priv(verbatim) break
	}
	# we reach here if html is empty, or verbatim is 1
	if !$len break
	# verbatim must be 1
	# append text until a </pre> is reached
	if {[regexp -indices -nocase $tkhtml_priv(verb_end_token) $html match]} {
	    set text [string range $html 0 [expr [lindex $match 0]-1]]
	    set html [string range $html [expr [lindex $match 1]+1] end]
	} else {
	    set text $html
	    set html ""
	}
	tkhtml_append_text $text
	if [info exists tkhtml_entity([string trim $tkhtml_priv(verb_end_token) <>])] {
	    tkhtml_do [string trim $tkhtml_priv(verb_end_token) <>]
	}
    }
    $w config -state disabled
}

proc tkhtml_defaults {} {
    global tkhtml_priv
    set tkhtml_priv(defaults_set) 1
    set tkhtml_priv(default_font) times
    set tkhtml_priv(fixed_font) courier
    set tkhtml_priv(font_size) medium
    set tkhtml_priv(small_points) "60 80 100 120 140 180 240"
    set tkhtml_priv(medium_points) "80 100 120 140 180 240 360"
    set tkhtml_priv(large_points) "100 120 140 180 240 360 480"
    set tkhtml_priv(huge_points) "120 140 180 240 360 480 640"
    set tkhtml_priv(ruler_height) 6
    set tkhtml_priv(indent_incr) 4
    set tkhtml_priv(w) {}
    set tkhtml_priv(counter) -1
}

proc tkhtml_set_font {font size} {
    global tkhtml_priv
    set tkhtml_priv(default_font) $font
    set tkhtml_priv(font) $font
    set tkhtml_priv(font_size) $size
}

proc tkhtml_setup {w} {
    global tkhtml_priv
    if ![info exists tkhtml_priv(defaults_set)] tkhtml_defaults
    set tkhtml_priv(font) $tkhtml_priv(default_font)
    set tkhtml_priv(left) 0
    set tkhtml_priv(left2) 0
    set tkhtml_priv(right) 0
    set tkhtml_priv(justify) L
    set tkhtml_priv(weight) 0
    set tkhtml_priv(slant) 0
    set tkhtml_priv(underline) 0
    set tkhtml_priv(verbatim) 0
    set tkhtml_priv(pre) 0
    set tkhtml_priv(title) {}
    set tkhtml_priv(in_title) 0
    set tkhtml_priv(color) black
    set tkhtml_priv(li_style) bullet
    set tkhtml_priv(anchor_count) 0
    set tkhtml_priv(verb_end_token) {}
    set tkhtml_priv(stack.font) {}
    set tkhtml_priv(stack.color) {}
    set tkhtml_priv(stack.justify) {}
    set tkhtml_priv(stack.li_style) {}
    set tkhtml_priv(stack.href) {}
    set tkhtml_priv(points_ndx) 2
    if {$tkhtml_priv(w) != $w} {
	set tkhtml_priv(w) $w
	$tkhtml_priv(w) tag config hr -relief sunken -borderwidth 2 \
	    -font -*-*-*-*-*-*-$tkhtml_priv(ruler_height)-*-*-*-*-*-*-*
	foreach elt [array names tkhtml_priv] {
	    if [regexp "^tag\\..*" $elt] {
		unset tkhtml_priv($elt)
	    }
	}
    }
}

proc tkhtml_define_font {name foundry family weight slant registry} {
    global tkhtml_priv
    lappend tkhtml_priv(font_names) $name
    set tkhtml_priv(font_info.$name) \
	[list $foundry $family $weight $slant $registry]
}

proc tkhtml_define_entity {name body} {
    global tkhtml_entity
    set tkhtml_entity($name) $body
}

proc tkhtml_do {cmd {argv {}}} {
    global tkhtml_priv tkhtml_entity
    eval $tkhtml_entity($cmd)
}

proc tkhtml_append_text {text} {
    global tkhtml_priv
    if !$tkhtml_priv(verbatim) {
	if !$tkhtml_priv(pre) {
	    regsub -all "\[ \n\r\t\]+" [string trim $text] " " text
	}
	regsub -nocase -all "&amp;" $text {\&} text
	regsub -nocase -all "&lt;" $text "<" text
	regsub -nocase -all "&gt;" $text ">" text
	if ![string length $text] return
    }
    if {!$tkhtml_priv(pre) && !$tkhtml_priv(in_title)} {
	set p [$tkhtml_priv(w) get "end - 2c"]
	set n [string index $text 0]
	if {![regexp "\[ \n(\]" $p] && ![regexp "\[\\.,')\]" $n]} {
	    $tkhtml_priv(w) insert end " "
	}
	$tkhtml_priv(w) insert end $text $tkhtml_priv(tag)
	return
    }
    if {$tkhtml_priv(pre) && !$tkhtml_priv(in_title)} {
	$tkhtml_priv(w) insert end $text $tkhtml_priv(tag)
	return
    }
    append tkhtml_priv(title) $text
}

proc tkhtml_title {} {
    global tkhtml_priv
    return $tkhtml_priv(title)
}

# a tag is constructed as: font?B?I?U?Points-LeftLeft2RightColorJustify
proc tkhtml_set_tag {} {
    global tkhtml_priv
    set i -1
    foreach var {foundry family weight slant registry} {
	set $var [lindex $tkhtml_priv(font_info.$tkhtml_priv(font)) [incr i]]
    }
    set x_font "-$foundry-$family-"
    set tag $tkhtml_priv(font)
    set args {}
    if {$tkhtml_priv(weight) > 0} {
	append tag "B"
	append x_font [lindex $weight 1]-
    } else {
	append x_font [lindex $weight 0]-
    }
    if {$tkhtml_priv(slant) > 0} {
	append tag "I"
	append x_font [lindex $slant 1]-
    } else {
	append x_font [lindex $slant 0]-
    }
    if {$tkhtml_priv(underline) > 0} {
	append tag "U"
	append args " -underline 1"
    }
    switch $tkhtml_priv(justify) {
	L { append args " -justify left" }
	R { append args " -justify right" }
	C { append args " -justify center" }
    }
    set pts [lindex $tkhtml_priv($tkhtml_priv(font_size)_points) \
	     $tkhtml_priv(points_ndx)]
    append tag $tkhtml_priv(points_ndx) - $tkhtml_priv(left) \
	$tkhtml_priv(left2) $tkhtml_priv(right) \
	$tkhtml_priv(color) $tkhtml_priv(justify)
    append x_font "normal-*-*-$pts-*-*-*-*-$registry-*"
    if $tkhtml_priv(anchor_count) {
	set href [tkhtml_peek href]
	set href_tag href[incr tkhtml_priv(counter)]
	set tags [list $tag $href_tag]
	if [info exists tkhtml_priv(command)] {
	    $tkhtml_priv(w) tag bind $href_tag <1> \
		[list tkhtml_href_click $tkhtml_priv(command) $href]
	}
	$tkhtml_priv(w) tag bind $href_tag <Enter> \
	    [list $tkhtml_priv(w) tag configure $href_tag \
                 -foreground red]
	$tkhtml_priv(w) tag bind $href_tag <Leave> \
	    [list $tkhtml_priv(w) tag configure $href_tag \
                 -foreground $tkhtml_priv(color)]
    } else {
	set tags $tag
    }
    if {![info exists tkhtml_priv(tag.$tag)]} {
	set tkhtml_priv(tag_font.$tag) 1
	eval $tkhtml_priv(w) tag configure $tag \
	    -font $x_font -foreground $tkhtml_priv(color) \
	    -lmargin1 $tkhtml_priv(left)m \
	    -lmargin2 $tkhtml_priv(left2)m $args
    }
    if [info exists href_tag] {
	$tkhtml_priv(w) tag raise $href_tag $tag
    }
    set tkhtml_priv(tag) $tags
}

proc tkhtml_reconfig_tags {w} {
    global tkhtml_priv
    foreach tag [$w tag names] {
	foreach font $tkhtml_priv(font_names) {
	    if [regexp "${font}(B?)(I?)(U?)(\[1-9\]\[0-9\]*)-" $tag t b i u points] {
		set j -1
		if {$font != $tkhtml_priv(fixed_font)} {
		    set font $tkhtml_priv(font)
		}
		foreach var {foundry family weight slant registry} {
		    set $var [lindex $tkhtml_priv(font_info.$font) [incr j]]
		}
		set x_font "-$foundry-$family-"
		if {$b == "B"} {
		    append x_font [lindex $weight 1]-
		} else {
		    append x_font [lindex $weight 0]-
		}
		if {$i == "I"} {
		    append x_font [lindex $slant 1]-
		} else {
		    append x_font [lindex $slant 0]-
		}
		set pts [lindex $tkhtml_priv($tkhtml_priv(font_size)_points) \
			 $points]
		append x_font "normal-*-*-$pts-*-*-*-*-$registry-*"
		$w tag config $tag -font $x_font
		break
	    }
	}
    }
}

proc tkhtml_push {stack value} {
    global tkhtml_priv
    lappend tkhtml_priv(stack.$stack) $value
}

proc tkhtml_pop {stack} {
    global tkhtml_priv
    set n [expr [llength $tkhtml_priv(stack.$stack)]-1]
    if {$n < 0} {
	puts "popping empty stack $stack"
	return ""
    }
    set val [lindex $tkhtml_priv(stack.$stack) $n]
    set tkhtml_priv(stack.$stack) [lreplace $tkhtml_priv(stack.$stack) $n $n]
    return $val
}

proc tkhtml_peek {stack} {
    global tkhtml_priv
    return [lindex $tkhtml_priv(stack.$stack) end]
}

proc tkhtml_parse_fields {array_var string} {
    upvar $array_var array
    foreach arg $string {
	if ![regexp "(\[^ \n\r=\]+)=\"?(\[^\"\n\r\t \]*)" $arg dummy field value] {
	    puts "malformed command field"
	    puts "field = \"$arg\""
	    continue
	}
	set array([string tolower $field]) $value
    }
}

proc tkhtml_set_command {cmd} {
    global tkhtml_priv
    set tkhtml_priv(command) $cmd
}

proc tkhtml_href_click {cmd href} {
    uplevel #0 $cmd $href
}

# define the fonts we're going to use
set tkhtml_priv(font_names) ""
tkhtml_define_font helvetica adobe helvetica "medium bold" "r o" iso8859
tkhtml_define_font courier adobe courier "medium bold" "r o" iso8859
tkhtml_define_font times adobe times "medium bold" "r i" iso8859
tkhtml_define_font symbol adobe symbol "medium medium" "r r" adobe

# define the entities we're going to handle
tkhtml_define_entity b { incr tkhtml_priv(weight); tkhtml_set_tag }
tkhtml_define_entity /b { incr tkhtml_priv(weight) -1; tkhtml_set_tag }
tkhtml_define_entity strong { incr tkhtml_priv(weight); tkhtml_set_tag }
tkhtml_define_entity /strong { incr tkhtml_priv(weight) -1; tkhtml_set_tag }
tkhtml_define_entity tt {
    tkhtml_push font $tkhtml_priv(font)
    set tkhtml_priv(font) $tkhtml_priv(fixed_font)
    tkhtml_set_tag
}
tkhtml_define_entity /tt {
    set tkhtml_priv(font) [tkhtml_pop font]
    tkhtml_set_tag
}
tkhtml_define_entity code { tkhtml_do tt }
tkhtml_define_entity /code { tkhtml_do /tt }
tkhtml_define_entity kbd { tkhtml_do tt }
tkhtml_define_entity /kbd { tkhtml_do /tt }
tkhtml_define_entity em { incr tkhtml_priv(slant); tkhtml_set_tag }
tkhtml_define_entity /em { incr tkhtml_priv(slant) -1; tkhtml_set_tag }
tkhtml_define_entity var { incr tkhtml_priv(slant); tkhtml_set_tag }
tkhtml_define_entity /var { incr tkhtml_priv(slant) -1; tkhtml_set_tag }
tkhtml_define_entity cite { incr tkhtml_priv(slant); tkhtml_set_tag }
tkhtml_define_entity /cite { incr tkhtml_priv(slant) -1; tkhtml_set_tag }
tkhtml_define_entity address {
    tkhtml_do br
    incr tkhtml_priv(slant)
    tkhtml_set_tag
}
tkhtml_define_entity /address {
    incr tkhtml_priv(slant) -1
    tkhtml_do br
    tkhtml_set_tag
}
tkhtml_define_entity /cite { incr tkhtml_priv(slant) -1; tkhtml_set_tag }

tkhtml_define_entity p {
    set x [$tkhtml_priv(w) get end-3c]
    set y [$tkhtml_priv(w) get end-2c]
    if {$x == "" && $y == ""} return
    if {$y == ""} {
	$tkhtml_priv(w) insert end "\n\n"
	return
    }
    if {$x == "\n" && $y == "\n"} return
    if {$y == "\n"} {
	$tkhtml_priv(w) insert end "\n"
	return
    }
    $tkhtml_priv(w) insert end "\n\n"
}
tkhtml_define_entity br {
    if {[$tkhtml_priv(w) get "end-2c"] != "\n"} {
	$tkhtml_priv(w) insert end "\n"
    }
}
tkhtml_define_entity title { set tkhtml_priv(in_title) 1 }
tkhtml_define_entity /title { set tkhtml_priv(in_title) 0 }

tkhtml_define_entity h1 { tkhtml_header 1 }
tkhtml_define_entity /h1 { tkhtml_/header 1 }
tkhtml_define_entity h2 { tkhtml_header 2 }
tkhtml_define_entity /h2 { tkhtml_/header 2 }
tkhtml_define_entity h3 { tkhtml_header 3 }
tkhtml_define_entity /h3 { tkhtml_/header 3 }
tkhtml_define_entity h4 { tkhtml_header 4 }
tkhtml_define_entity /h4 { tkhtml_/header 4 }
tkhtml_define_entity h5 { tkhtml_header 5 }
tkhtml_define_entity /h5 { tkhtml_/header 5 }
tkhtml_define_entity h6 { tkhtml_header 6 }
tkhtml_define_entity /h6 { tkhtml_/header 6 }

proc tkhtml_header {level} {
    global tkhtml_priv
    tkhtml_do p
    set tkhtml_priv(points_ndx) [expr 6-$level]
    incr tkhtml_priv(weight)
    tkhtml_set_tag
}

proc tkhtml_/header {level} {
    global tkhtml_priv
    set tkhtml_priv(points_ndx) 2
    incr tkhtml_priv(weight) -1
    tkhtml_set_tag
    tkhtml_do p
}

tkhtml_define_entity pre {
    tkhtml_do tt
    tkhtml_do br
    incr tkhtml_priv(pre)
}
tkhtml_define_entity /pre {
    tkhtml_do /tt
    set tkhtml_priv(pre) 0
    tkhtml_do p
}

tkhtml_define_entity hr {
    tkhtml_do p
    $tkhtml_priv(w) insert end "\n" hr
}
tkhtml_define_entity a {
    tkhtml_parse_fields ar $argv
    tkhtml_push color $tkhtml_priv(color)
    if [info exists ar(href)] {
	tkhtml_push href $ar(href)
    } else {
	tkhtml_push href {}
    }
    incr tkhtml_priv(anchor_count)
    set tkhtml_priv(color) blue
    incr tkhtml_priv(underline)
    tkhtml_set_tag
}
tkhtml_define_entity /a {
    tkhtml_pop href
    incr tkhtml_priv(anchor_count) -1
    set tkhtml_priv(color) [tkhtml_pop color]
    incr tkhtml_priv(underline) -1
    tkhtml_set_tag
}
tkhtml_define_entity center {
    tkhtml_push justify $tkhtml_priv(justify)
    set tkhtml_priv(justify) C
    tkhtml_set_tag
}
tkhtml_define_entity /center {
    set tkhtml_priv(justify) [tkhtml_pop justify]
    tkhtml_set_tag
}
tkhtml_define_entity ul {
    if $tkhtml_priv(left) {
	tkhtml_do br
    } else {
	tkhtml_do p
    }
    incr tkhtml_priv(left) $tkhtml_priv(indent_incr)
    incr tkhtml_priv(left2) [expr $tkhtml_priv(indent_incr)+3]
    tkhtml_push li_style $tkhtml_priv(li_style)
    set tkhtml_priv(li_style) bullet
    tkhtml_set_tag
}
tkhtml_define_entity /ul {
    incr tkhtml_priv(left) -$tkhtml_priv(indent_incr)
    incr tkhtml_priv(left2) -[expr $tkhtml_priv(indent_incr)+3]
    set tkhtml_priv(li_style) [tkhtml_pop li_style]
    tkhtml_set_tag
    tkhtml_do p
}
tkhtml_define_entity li {
    tkhtml_do br
    if {$tkhtml_priv(li_style) == "bullet"} {
	set old_font $tkhtml_priv(font)
	set tkhtml_priv(font) symbol
	tkhtml_set_tag
	$tkhtml_priv(w) insert end "\xb7" $tkhtml_priv(tag)
	set tkhtml_priv(font) $old_font
	tkhtml_set_tag
    }
}
tkhtml_define_entity listing { tkhtml_do pre }
tkhtml_define_entity /listing { tkhtml_do /pre }
tkhtml_define_entity code { tkhtml_do pre }
tkhtml_define_entity /code { tkhtml_do /pre }

tkhtml_define_entity img {
    tkhtml_parse_fields ar $argv
    if [info exists ar(src)] {
	set file $ar(src)
	if [info exists tkhtml_priv(image_hook)] {
	    set img [eval $tkhmlt_priv(image_hook) $file]
	} else {
	    if [catch {set img [image create photo -file $file]} err] {
		puts stderr "Couldn't create image $file: $err"
		return
	    }
	}
	set align bottom
	if [info exists ar(align)] {
	    set align [string tolower $ar(align)]
	}
	ttk::label $tkhtml_priv(w).$img -image $img
	$tkhtml_priv(w) window create end -window $tkhtml_priv(w).$img \
	    -align $align
    }
}
