#
# $Id$
#

dialog feedback {
    param steps 10
    param title {}
    param barwidth 200
    param barheight 20
    param barcolor DodgerBlue
    member step 0
    member old_focus {}
    method create {} {
	$self config -bd 4 -relief ridge
	label $self.title
	pack $self.title -side top -fill x -padx 2 -pady 2
        frame $self.spacer
        frame $self.bar -relief raised -bd 2 -highlightthickness 0
	pack $self.spacer $self.bar -side top -padx 10 -anchor w
        label $self.percentage -text 0%
	pack $self.percentage -side top -fill x -padx 2 -pady 2
        wm transient $self .
    }
    method reconfig {} {
	$self.title config -text $slot(title)
	$self.spacer config -width $slot(barwidth)
	$self.bar config -height $slot(barheight) -bg $slot(barcolor)
        center_window $self
	update idletasks
    }
    method destroy {} {
	if {[grab current $self] == $self} {
	    grab release $self
	}
    }
    method grab {} {
	while {[catch {grab set $self}]} {
	}
    }
    method reset {} {
	set slot(step) -1
	$self step
    }
    method step {{inc 1}} {
	if {$slot(step) >= $slot(steps)} return
        incr slot(step) $inc
        set fraction [expr 1.0*$slot(step)/$slot(steps)]
        $self.percentage config -text [format %.0f%% [expr 100.0*$fraction]]
        $self.bar config -width [expr int($slot(barwidth)*$fraction)]
        update
    }
}

