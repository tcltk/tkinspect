#
# $Id$
#
# Maintains the list of windows, and caches window class information.
# (the list is shared between windows_list and menus_list.)
#

object_class windows_info {
    member windows {}
    method clear {} {
	foreach w $slot(windows) {
	    if [info exists slot($w.class)] {
		unset slot($w.class)
	    }
	}
	set slot(windows) {}
    }
    method get_windows {} { return $slot(windows) }
    method append_windows {target result_var parent} {
	upvar $result_var result
	foreach w [send $target winfo children $parent] {
	    lappend slot(windows) $w
	    $self append_windows $target result $w
	}
    }
    method update {target} {
	$self clear
	set slot(windows) [send $target winfo children .]
	feedback .feedback -title "Getting Windows" \
	    -steps [llength $slot(windows)]
	.feedback grab
	foreach w $slot(windows) {
	    $self append_windows $target windows $w
	    .feedback step
	    update idletasks
	}
	destroy .feedback
    }
    method get_class {target w} {
	if ![info exists slot($w.class)] {
	    set slot($w.class) [send $target [list winfo class $w]]
	}
	return $slot($w.class)
    }
}
