#
# $Id$
#
# Handles browsing menus.
#

widget menus_list {
    object_include tkinspect_list
    param title "Menus"
    method get_item_name {} { return menu }
    method update_self {target} {
	$slot(main) windows_info update $target
	$self update $target
    }
    method update {target} {
	$self clear
	foreach w [$slot(main) windows_info get_windows] {
	    if {[$slot(main) windows_info get_class $target $w] == "Menu"} {
		$self append $w
	    }
	}
    }
    method retrieve {target menu} {
	set end [send $target $menu index end]
	if {$end == "none"} { set end 0 } else { incr end }
	set result "# menu $menu has $end entries\n"
	for {set i 0} {$i < $end} {incr i} {
	    append result "$menu entryconfigure $i"
	    foreach spec [send $target [list $menu entryconfig $i]] {
		append result " \\\n\t[lindex $spec 0] [list [lindex $spec 4]]"
	    }
	    append result "\n"
	}
	return $result
    }
    method send_filter {value} {
	return $value
    }
}
