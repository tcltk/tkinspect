#
# $Id$
#

widget windows_list {
    object_include tkinspect_list
    param title "Windows"
    member filter_empty_window_configs 1
    member filter_window_class_config 1
    member filter_window_pack_in 1
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
	    -value bindings -label "Window Bindings" -underline 7 \
            -command "$self mode_changed"
        $slot(menu) add radiobutton -variable [object_slotname mode] \
	    -value classbindings -label "Window Class Bindings" -underline 8 \
            -command "$self mode_changed"
        $slot(menu) add separator
        $slot(menu) add checkbutton \
	    -variable [object_slotname filter_empty_window_configs] \
            -label "Filter Empty Window Options" -underline 0
        $slot(menu) add checkbutton \
	    -variable [object_slotname filter_window_class_config] \
            -label "Filter Window -class Options" -underline 0
        $slot(menu) add checkbutton \
	    -variable [object_slotname filter_window_pack_in] \
            -label "Filter Pack -in Options" -underline 0
    }
    method get_windows {target result_var parent} {
	upvar $result_var result
	foreach w [send $target winfo children $parent] {
	    lappend result $w
	    $self get_windows $target result $w
	}
    }
    method update {target} {
	$self clear
	set windows .
	$self get_windows $target windows .
	foreach w $windows {
	    $self append $w
	}
    }
    method set_mode {mode} {
	set slot(mode) $mode
	$self mode_changed
    }
    method clear {} {
	tkinspect_list:clear $self
	if {$slot(mode) == "classbindings"} {
	    $self.list insert 0 "all"
	}
    }
    method mode_changed {} {
	if {[$slot(main) last_list] == $self} {
	    $slot(main) select_list_item $self $slot(current_item)
	}
	if {[$self.list get 0] == "all"} {
	    $self.list delete 0
	}
	if {$slot(mode) == "classbindings"} {
	    $self.list insert 0 "all"
	}
    }
    method retrieve {target window} {
	set result [$self retrieve_$slot(mode) $target $window]
	if {$window != "all"} {
	    set old_bg [send $target [list $window cget -background]]
	    send $target [list $window config -background #ff69b4]
	    send $target [list after 200 \
		       [list catch [list $window config -background $old_bg]]]
	}
	return $result
    }
    method retrieve_config {target window} {
	set result "# window configuration of $window\n"
	append result "$window config"
	foreach spec [send $target [list $window config]] {
	    if {[llength $spec] == 2} continue
	    append result " \\\n\t[lindex $spec 0] [list [lindex $spec 4]]"
	}
	append result "\n"
	return $result
    }
    method format_packing_info {result_var window info} {
	upvar $result_var result
	append result "pack configure $window"
	set len [llength $info]
	for {set i 0} {$i < $len} {incr i 2} {
	    append result " \\\n\t[lindex $info $i] [lindex $info [expr $i+1]]"
	}
	append result "\n"
    }
    method retrieve_packing {target window} {
	set result "# packing info for $window\n"
	if [catch {send $target pack info $window} info] {
	    append result "# $info\n"
	} else {
	    $self format_packing_info result $window $info
	}
	return $result
    }
    method retrieve_slavepacking {target window} {
	set result "# packing info for slaves of $window\n"
	foreach slave [send $target pack slaves $window] {
	    $self format_packing_info result $slave \
		[send $target pack info $slave]
	}
	return $result
    }
    method retrieve_bindings {target window} {
	set result "# bindings of $window"
	foreach sequence [send $target bind $window] {
	    append result "\nbind $window $sequence "
	    lappend result [send $target bind $window $sequence]
	}
	append result "\n"
	return $result
    }
    method retrieve_classbindings {target window} {
	if {$window == "all"} {
	    set class "all"
	} else {
	    set class [send $target winfo class $window]
	}
	set result "# class bindings for $window\n# class: $class"
	foreach sequence [send $target bind $class] {
	    append result "\nbind $class $sequence "
	    lappend result [send $target bind $class $sequence]
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
