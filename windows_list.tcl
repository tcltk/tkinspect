#
# $Id$
#

widget windows_list {
    object_include tkinspect_list
    param title "Windows"
    param get_window_info 1
    param filter_empty_window_configs 1
    param filter_window_class_config 1
    param filter_window_pack_in 1
    member mode config
    method get_item_name {} { return window }
    method create {} {
	tkinspect_list:create $self
	$slot(menu) add separator
	$slot(menu) add radiobutton -variable [object_slotname mode] \
	    -value config -label "Window Configuration" -underline 7 \
            -command "$self mode_changed"
        $slot(menu) add radiobutton -variable [object_slotname mode] \
	    -value packing -label "Window Packing" -underline 7 \
            -command "$self mode_changed"
        $slot(menu) add radiobutton -variable [object_slotname mode] \
	    -value slavepacking -label "Slave Window Packing" -underline 1 \
            -command "$self mode_changed"
	$slot(menu) add radiobutton -variable [object_slotname mode] \
	    -value bindtagsplus -label "Window Bindtags & Bindings" \
	    -command "$self mode_changed" -underline 16
	$slot(menu) add radiobutton -variable [object_slotname mode] \
	    -value bindtags -label "Window Bindtags" \
	    -command "$self mode_changed" -underline 11
        $slot(menu) add radiobutton -variable [object_slotname mode] \
	    -value bindings -label "Window Bindings" -underline 7 \
            -command "$self mode_changed"
        $slot(menu) add radiobutton -variable [object_slotname mode] \
	    -value classbindings -label "Window Class Bindings" -underline 8 \
            -command "$self mode_changed"
        $slot(menu) add separator
        $slot(menu) add checkbutton \
	    -variable [object_slotname filter_empty_window_configs] \
            -label "Filter Empty Window Options"
        $slot(menu) add checkbutton \
	    -variable [object_slotname filter_window_class_config] \
            -label "Filter Window -class Options"
        $slot(menu) add checkbutton \
	    -variable [object_slotname filter_window_pack_in] \
            -label "Filter Pack -in Options"
        $slot(menu) add separator
	$slot(menu) add checkbutton \
	    -variable [object_slotname get_window_info] \
            -label "Get Window Information" -underline 0
    }
    method update_self {target} {
	$slot(main) windows_info update $target
	$self update $target
    }
    method update {target} {
	if !$slot(get_window_info) return
	$self clear
	foreach w [$slot(main) windows_info get_windows] {
	    $self append $w
	}
    }
    method set_mode {mode} {
	set slot(mode) $mode
	$self mode_changed
    }
    method clear {} {
	tkinspect_list:clear $self
    }
    method mode_changed {} {
	if {[$slot(main) last_list] == $self} {
	    $slot(main) select_list_item $self $slot(current_item)
	}
    }
    method retrieve {target window} {
	set result [$self retrieve_$slot(mode) $target $window]
	set old_bg [send $target [list $window cget -background]]
	send $target [list $window config -background #ff69b4]
	send $target [list after 200 \
		      [list catch [list $window config -background $old_bg]]]
	return $result
    }
    method retrieve_config {target window} {
	set result "# window configuration of [list $window]\n"
	append result "[list $window] config"
	foreach spec [send $target [list $window config]] {
	    if {[llength $spec] == 2} continue
	    append result " \\\n\t[lindex $spec 0] [list [lindex $spec 4]]"
	}
	append result "\n"
	return $result
    }
    method format_packing_info {result_var window info} {
	upvar $result_var result
	append result "pack configure [list $window]"
	set len [llength $info]
	for {set i 0} {$i < $len} {incr i 2} {
	    append result " \\\n\t[lindex $info $i] [lindex $info [expr $i+1]]"
	}
	append result "\n"
    }
    method retrieve_packing {target window} {
	set result "# packing info for [list $window]\n"
	if [catch {send $target [list pack info $window]} info] {
	    append result "# $info\n"
	} else {
	    $self format_packing_info result $window $info
	}
	return $result
    }
    method retrieve_slavepacking {target window} {
	set result "# packing info for slaves of [list $window]\n"
	foreach slave [send $target [list pack slaves $window]] {
	    $self format_packing_info result $slave \
		[send $target [list pack info $slave]]
	}
	return $result
    }
    method retrieve_bindtags {target window} {
	set result "# bindtags of [list $window]\n"
	set tags [send $target [list bindtags $window]]
	append result [list bindtags $window $tags]
	append result "\n"
	return $result
    }
    method retrieve_bindtagsplus {target window} {
	set result "# bindtags of [list $window]\n"
	set tags [send $target [list bindtags $window]]
	append result [list bindtags $window $tags]
	append result "\n# bindings (in bindtag order)..."
	foreach tag $tags {
	    foreach sequence [send $target [list bind $tag]] {
		append result "\nbind $tag $sequence "
		lappend result [send $target [list bind $tag $sequence]]
	    }
	}
	append result "\n"
	return $result
    }
    method retrieve_bindings {target window} {
	set result "# bindings of [list $window]"
	foreach sequence [send $target [list bind $window]] {
	    append result "\nbind $window $sequence "
	    lappend result [send $target [list bind $window $sequence]]
	}
	append result "\n"
	return $result
    }
    method retrieve_classbindings {target window} {
	set class [$slot(main) windows_info get_class $target $window]
	set result "# class bindings for $window\n# class: $class"
	foreach sequence [send $target [list bind $class]] {
	    append result "\nbind $class $sequence "
	    lappend result [send $target [list bind $class $sequence]]
	}
	append result "\n"
	return $result
    }
    method send_filter {value} {
	if $slot(filter_empty_window_configs) {
	    regsub -all {[ \t]*-[^ \t]+[ \t]+{}([ \t]*\\?\n?)?} $value {\1} \
		value
	}
	if $slot(filter_window_class_config) {
	    regsub -all "(\n)\[ \t\]*-class\[ \t\]+\[^ \\\n\]*\n?" $value \
		"\\1" value
	}
	if $slot(filter_window_pack_in) {
	    regsub -all "(\n)\[ \t\]*-in\[ \t\]+\[^ \\\n\]*\n?" $value \
		"\\1" value
	}
	return $value
    }
}
