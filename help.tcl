#
# $Id$
#

lappend auto_path /usr/local/lib/stl

dialog help_window {
    param topics {}
    param width 50
    param height 35
    param helpdir .
    method create {} {
	frame $self.menu -relief raised -bd 2
	menubutton $self.menu.topics -text "Topics" -underline 0 \
	    -menu $self.menu.topics.m
	pack $self.menu.topics -in $self.menu -side left
	set m [menu $self.menu.topics.m]
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
	set slot(topic) $topic
	$self read_topic $topic
	wm title $self "Help: $topic"
    }
    method read_topic {topic} {
	set f [open $slot(helpdir)/$topic.html r]
	set txt [read $f]
	close $f
	feedback .help_feedback -steps [set slot(len) [string length $txt]]
	set slot(remaining) $slot(len)
	grab set .help_feedback
	tkhtml_set_render_hook "$self update_feedback"
	tkhtml_set_command "$self follow_link"
	tkhtml_render $self.text.t $txt
	grab release .help_feedback
	destroy .help_feedback
    }
    method follow_link {link} {
	$self read_topic [file root $link]
    }
    method update_feedback {n} {
	if {($slot(remaining) - $n) > .1*$slot(len)} {
	    .help_feedback step [expr $slot(remaining) - $n]
	    update idletasks
	    set slot(remaining) $n
	}
    }
}
