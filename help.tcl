#
# $Id$
#

dialog help_window {
    param topics {}
    param width 50
    param height 35
    param helpdir .
    member history {}
    member history_ndx -1
    member history_len 0
    method create {} {
	frame $self.menu -relief raised -bd 2
	menubutton $self.menu.topics -text "Topics" -underline 0 \
	    -menu $self.menu.topics.m
	pack $self.menu.topics -in $self.menu -side left
	set m [menu $self.menu.topics.m]
	menubutton $self.menu.navigate -text "Navigate" -underline 0 \
	    -menu $self.menu.navigate.m
	pack $self.menu.navigate -in $self.menu -side left
	set m [menu $self.menu.navigate.m]
	$m add command -label "Forward" -underline 0 -state disabled \
	    -command "$self forward"
	$m add command -label "Back" -underline 0 -state disabled \
	    -command "$self back"
	$m add cascade -label "Go" -underline 0 -menu $m.go
	menu $m.go -postcommand "$self fill_go_menu"
	frame $self.text -bd 2 -relief raised
	scrollbar $self.text.sb -command "$self.text.t yview"
	text $self.text.t -relief sunken -bd 2 -yscroll "$self.text.sb set" \
	    -wrap word -setgrid 1
	set t $self.text.t
	pack $self.text.sb -in $self.text -side right -fill y
	pack $self.text.t -in $self.text -side left -fill both -expand yes
	pack $self.menu -in $self -side top -fill x
	pack $self.text -in $self -side bottom -fill both -expand yes
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
	set slot(topic) $topic
	wm title $self "Help: $topic"
	set f [open $slot(helpdir)/$topic.html r]
	set txt [read $f]
	close $f
	feedback .help_feedback -steps [set slot(len) [string length $txt]] \
	    -title "Rendering HTML"
	set slot(remaining) $slot(len)
	grab set .help_feedback
	tkhtml_set_render_hook "$self update_feedback"
	tkhtml_set_command "$self follow_link"
	tkhtml_render $self.text.t $txt
	grab release .help_feedback
	destroy .help_feedback
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
	$self show_topic [file root $link]
    }
    method forward {} {
	incr slot(history_ndx)
	$self read_topic [lindex $slot(history) $slot(history_ndx)]
    }
    method back {} {
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
}
