#
# $Id$
#

widget value {
    param width 80
    param height 20
    param main
    method create {} {
	$self config -bd 2 -relief raised -highlightthickness 0
	pack [frame $self.title] -side top -fill x
	pack [label $self.title.l -text "Value:  "] -side left
	label $self.title.vname -anchor w \
	    -textvariable [object_slotname value_name]
	pack $self.title.vname -fill x
	scrollbar $self.sb -relief sunken -bd 1 -command "$self.t yview"
	text $self.t -yscroll "$self.sb set"
	pack $self.sb -side right -fill y
	pack $self.t -side right -fill both -expand 1
	bind $self.t <Control-x><Control-s> "$self send_value"
    }
    method reconfig {} {
	$self.t config -width $slot(width) -height $slot(height)
    }
    method set_value {name value} {
	$self.t delete 1.0 end
	$self.t insert 1.0 $value
	set slot(value_name) $name
    }
    method set_send_filter {command} {
	set slot(send_filter) $command
    }
    method send_value {} {
	send [$slot(main) target] \
	    [eval $slot(send_filter) [list [$self.t get 1.0 end]]]
	$slot(main) status "Value sent"
    }
}
