# afters_list.tcl - Originally written by Paul Healy <ei9gl@indigo.ie>
#
# $Id$

widget afters_list {
    object_include tkinspect_list
    param title "Afters"
    method get_item_name {} { return after }
    method update {target} {
	$self clear
	foreach after [lsort [send $target after info]] {
	    $self append $after
	}
    }
    method retrieve {target after} {
        set cmd [list after info $after]
        set retcode [catch [list send $target $cmd] msg]
        if {$retcode != 0} {
            set result "Error: $msg\n"
        } elseif {$msg != ""} {
            set script [lindex $msg 0]
            set type [lindex $msg 1]
            set result "# after type=$type\n"
            # there is no way to get even an indication of when a timer will
            # expire. tcl should be patched to optionally return this.
            switch $type {
                idle  {append result "after idle $script\n"}
                timer {append result "after ms $script\n"}
                default {append result "after $type $script\n"}
            }
        } else {
            set result "Error: empty after $after?\n"
        }
	return $result
    }
    method send_filter {value} {
	return $value
    }
}
