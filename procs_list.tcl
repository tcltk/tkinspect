#
# $Id$
#

widget procs_list {
    object_include tkinspect_list
    param title "Procs"
    method get_item_name {} { return proc }
    method update {target} {
	$self clear
	foreach proc [lsort [names::procs $target]] {
	    $self append $proc
	}
    }
    method retrieve {target proc} {
	set result [list proc $proc]
	set formals {}
	foreach arg [send $target [list ::info args $proc]] {
	    if [send $target [list ::info default $proc $arg __tkinspect_default_arg__]] {
		lappend formals [list $arg [send $target \
				    [list ::set __tkinspect_default_arg__]]]
	    } else {
		lappend formals $arg
	    }
	}
	send $target ::catch {::unset __tkinspect_default_arg__}
	lappend result $formals
	lappend result [send $target [list ::info body $proc]]
	return $result
    }
    method send_filter {value} {
	return $value
    }
}
