#
# $Id$
#

dialog filter_editor {
    param list
    member patterns
    member filter_type exclude
    method create {} {
        frame $self.top
        label $self.l -text "Pattern:"
        entry $self.e -width 40 -relief sunken
        pack $self.l -in $self.top -side left
        pack $self.e -in $self.top -side left -fill x
        pack $self.top -side top -fill x -pady .25c
        frame $self.buttons -bd 3
        button $self.ok -text "Apply" -command "$self apply"
        button $self.close -text "Close" -command "wm withdraw $self"
        button $self.add -text "Add Pattern" \
	    -command "$self add_pattern"
        button $self.del -text "Delete Pattern(s)" \
	    -command "$self delete_patterns"
        radiobutton $self.inc -variable [object_slotname filter_type] \
	    -value include -relief flat -text "Include Patterns"
        radiobutton $self.exc -variable [object_slotname filter_type] \
	    -value exclude -relief flat -text "Exclude Patterns"
        pack $self.inc $self.exc $self.add $self.del -in $self.buttons \
	    -side top -fill x -pady .1c -anchor w
        pack $self.close $self.ok -in $self.buttons \
	    -side bottom -fill x -pady .1c
        pack $self.buttons -in $self -side left -fill y
        frame $self.lframe
        scrollbar $self.sb -command "$self.list yview"
        listbox $self.list -yscroll "$self.sb set" -relief raised \
            -width 40 -height 10 -selectmode multiple
        pack $self.sb -in $self.lframe -side right -fill y
        pack $self.list -in $self.lframe -side right -fill both -expand yes
        pack $self.lframe -in $self -side right -fill both -expand yes
	set title "Edit [$slot(list) cget -title] Filter"
	wm title $self $title
	wm iconname $self $title
	foreach pat [$slot(list) cget -patterns] {
	    $self.list insert end $pat
	    lappend slot(patterns) $pat
	}
    }
    method reconfig {} {
    }
    method apply {} {
	$slot(list) config -patterns $slot(patterns) \
	    -filter_type $slot(filter_type)
	$slot(list) update_needed
    }
    method add_pattern {} {
	set pat [$self.e get]
	if {[string length $pat]} {
	    lappend slot(patterns) $pat
	    $self.list insert end $pat
	}
    }
    method delete_patterns {} {
	while {[string length [set s [$self.list curselection]]]} {
	    set pat [$self.list get [lindex $s 0]]
	    set ndx [lsearch -exact $slot(patterns) $pat]
	    set slot(patterns) [lreplace $slot(patterns) $ndx $ndx]
	    $self.list delete [lindex $s 0]
	}
    }
}

widget tkinspect_list {
    param command {}
    param title {}
    param width 30
    param height 12
    param main
    param patterns {}
    param filter_type exclude
    member current_item
    member menu
    member contents {}
    method create {} {
	$self config -bd 2 -relief raised
	pack [label $self.title -anchor w] -side top -fill x
	scrollbar $self.sb -command "$self.list yview" -relief sunken -bd 1
	listbox $self.list -relief sunken -exportselection 0 \
	    -yscroll "$self.sb set" -selectmode single
	bind $self.list <1> "$self click %x %y; continue"
	pack $self.sb -side right -fill y
	pack $self.list -side right -fill both -expand yes
	set slot(menu) [$slot(main) add_menu $slot(title)]
	$slot(menu) add command -label "Edit Filter..." \
	    -command "$self edit_filter"
	$slot(menu) add command -label "Remove List" \
	    -command "$self remove" -state disabled
    }
    method reconfig {} {
	$self.title config -text "$slot(title):"
	$self.list config -width $slot(width) -height $slot(height)
    }
    method clear {} {
	set slot(contents) ""
    }
    method append {item} {
	lappend slot(contents) $item
	$self update_needed
    }
    method update_needed {} {
	if ![info exists slot(update_pending)] {
	    set slot(update_pending) 1
	    after 0 $self do_update
	}	
    }
    method do_update {} {
	unset slot(update_pending)
	$self.list delete 0 end
	if {$slot(filter_type) == "exclude"} {
	    set x 1
	} else {
	    set x 0
	}
	foreach item $slot(contents) {
	    set include $x
	    foreach pattern $slot(patterns) {
		if [regexp -- $pattern $item] {
		    set include [expr !$x]
		    break
		}
	    }
	    if $include {
		$self.list insert end $item
	    }
	}
    }
    method click {x y} {
	if [string length $slot(command)] {
	    set slot(current_item) [$self.list get @$x,$y]
	    if [string length $slot(current_item)] {
		uplevel #0 [concat $slot(command) $slot(current_item)]
	    }
	}
    }
    method remove {} {
	$slot(main) destroy_menu $slot(title)
	object_delete $self
    }
    method edit_filter {} {
	if [winfo exists $self.editor] {
	    wm deiconify $self.editor
	} else {
	    filter_editor $self.editor -list $self
	    center_window $self.editor
	}
    }
}
