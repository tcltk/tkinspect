#
# $Id$
#

dialog help_window {
    param topics {}
    param width 100
    param height 35
    param helpdir .
    member history {}
    member history_ndx -1
    member history_len 0
    member rendering 0
    method create {} {
	ttk::frame $self.menu
	ttk::menubutton $self.menu.topics -text "Topics" -underline 0 \
	    -menu $self.menu.topics.m
	pack $self.menu.topics -in $self.menu -side left
	set m [menu $self.menu.topics.m]
	ttk::menubutton $self.menu.navigate -text "Navigate" -underline 0 \
	    -menu $self.menu.navigate.m
	pack $self.menu.navigate -in $self.menu -side left
	set m [menu $self.menu.navigate.m]
	$m add command -label "Forward" -underline 0 -state disabled \
	    -command "$self forward" -accelerator f
	$m add command -label "Back" -underline 0 -state disabled \
	    -command "$self back" -accelerator b
	$m add cascade -label "Go" -underline 0 -menu $m.go
	menu $m.go -postcommand "$self fill_go_menu"
	ttk::frame $self.text
	ttk::scrollbar $self.text.sb -command "$self.text.t yview"
	text $self.text.t -yscrollcommand "$self.text.sb set" \
	    -wrap word -setgrid 1 -background white
	set t $self.text.t
	pack $self.text.sb -in $self.text -side right -fill y
	pack $self.text.t -in $self.text -side left -fill both -expand yes
	pack $self.menu -in $self -side top -fill x
	pack $self.text -in $self -side bottom -fill both -expand yes
	bind $self <Key-f> "$self forward"
	bind $self <Key-b> "$self back"
	bind $self <Alt-Right> "$self forward"
	bind $self <Alt-Left> "$self back"
	bind $self <Key-space> "$self page_forward"
	bind $self <Key-Next> "$self page_forward"
	bind $self <Key-BackSpace> "$self page_back"
	bind $self <Key-Prior> "$self page_back"
	bind $self <Key-Delete> "$self page_back"
	bind $self <Key-Down> "$self line_forward"
	bind $self <Key-Up> "$self line_back"
    }
    method reconfig {} {
	set m $self.menu.topics.m
	$m delete 0 last
	foreach topic $slot(topics) {
	    $m add radiobutton -variable [object_slotname topic] \
		-value $topic \
		-label $topic \
		-command [list $self show_topic $topic]
	}
	$m add separator
	$m add command -label "Close Help" -underline 0 \
	    -command "destroy $self"
	$self.text.t config -width $slot(width) -height $slot(height)
    }
    method show_topic {topic} {
	incr slot(history_ndx)
	set slot(history) [lrange $slot(history) 0 $slot(history_ndx)]
	set slot(history_len) [expr $slot(history_ndx) + 1]
	lappend slot(history) $topic
	$self read_topic $topic
    }
    method read_topic {topic} {
        # probably should use uri::geturl from tcllib
	set slot(topic) $topic
	wm title $self "Help: $topic"
        set filename [file join $slot(helpdir) $topic]
        if {![file exist $filename]} {
            append filename .html
        }
	set f [open $filename r]
	set txt [read $f]
	close $f

        # Fix for
        if [string match -nocase "*ChangeLog" $filename] {
            set txt "<html><body><pre>$txt</pre></body></html>"
        }

	feedback .help_feedback -steps [set slot(len) [string length $txt]] \
	    -title "Rendering HTML"
	.help_feedback grab
	set slot(remaining) $slot(len)
	set slot(rendering) 1
	tkhtml_set_render_hook "$self update_feedback"
	tkhtml_set_command "$self follow_link"
	tkhtml_render $self.text.t $txt
	destroy .help_feedback
	set slot(rendering) 0
	set m $self.menu.navigate.m
	if {($slot(history_ndx)+1) < $slot(history_len)} {
	    $m entryconfig 1 -state normal
	} else {
	    $m entryconfig 1 -state disabled
	}
	if {$slot(history_ndx) > 0} {
	    $m entryconfig 2 -state normal
	} else {
	    $m entryconfig 2 -state disabled
	}
    }
    method follow_link {link} {
	$self show_topic $link
    }
    method forward {} {
	if {$slot(rendering) || ($slot(history_ndx)+1) >= $slot(history_len)} return
	incr slot(history_ndx)
	$self read_topic [lindex $slot(history) $slot(history_ndx)]
    }
    method back {} {
	if {$slot(rendering) || $slot(history_ndx) <= 0} return
	incr slot(history_ndx) -1
	$self read_topic [lindex $slot(history) $slot(history_ndx)]
    }
    method fill_go_menu {} {
	set m $self.menu.navigate.m.go
	catch {$m delete 0 last}
	for {set i [expr [llength $slot(history)]-1]} {$i >= 0} {incr i -1} {
	    set topic [lindex $slot(history) $i]
	    $m add command -label $topic \
		-command [list $self show_topic $topic]
	}
    }
    method update_feedback {n} {
	if {($slot(remaining) - $n) > .1*$slot(len)} {
	    .help_feedback step [expr $slot(remaining) - $n]
	    update idletasks
	    set slot(remaining) $n
	}
    }
    method page_forward {} {
	$self.text.t yview scroll 1 pages
    }
    method page_back {} {
	$self.text.t yview scroll -1 pages
    }
    method line_forward {} { $self.text.t yview scroll 1 units }
    method line_back {} { $self.text.t yview scroll -1 units }
}
