#
# $Id$
#

widget clickable_list {
    param command {}
    param title {}
    param width 30
    param height 12
    param main
    method create {} {
	$self config -bd 2 -relief raised
	pack [label $self.title -anchor w] -side top -fill x
	scrollbar $self.sb -command "$self.list yview" -relief sunken -bd 1
	listbox $self.list -relief sunken -exportselection 0 \
	    -yscroll "$self.sb set" -selectmode single
	bind $self.list <1> "$self click %x %y; continue"
	pack $self.sb -side right -fill y
	pack $self.list -side right -fill both -expand yes
    }
    method reconfig {} {
	$self.title config -text $slot(title)
	$self.list config -width $slot(width) -height $slot(height)
    }
    method list args {
	eval $self.list $args
    }
    method click {x y} {
	if [string length $slot(command)] {
	    set item [$self.list get @$x,$y]
	    if [string length $item] {
		uplevel #0 [concat $slot(command) $item]
	    }
	}
    }
}

widget procs_list {
    object_include clickable_list
    param title "Procs:"
    method get_item_name {} { return proc }
    method update {target} {
	$self list delete 0 end
	foreach proc [lsort [send $target info procs]] {
	    $self list insert end $proc
	}
    }
    method retrieve {target proc} {
	set result [list proc $proc]
	set formals {}
	foreach arg [send $target [list info args $proc]] {
	    if [send $target [list info default $proc $arg __tkinspect_default_arg__]] {
		lappend formals [list $arg [send $target \
				    [list set __tkinspect_default_arg__]]]
	    } else {
		lappend formals $arg
	    }
	}
	send $target catch {unset __tkinspect_default_arg__}
	lappend result $formals
	lappend result [send $target [list info body $proc]]
	return $result
    }
    method send_filter {value} {
	return $value
    }
}

widget globals_list {
    object_include clickable_list
    param title "Globals:"
    method get_item_name {} { return global }
    method update {target} {
	$self list delete 0 end
	foreach var [lsort [send $target info globals]] {
		$self list insert end $var
	}
    }
    method retrieve {target var} {
	if ![send $target [list array size $var]] {
	    return [list set $var [send $target [list set $var]]]
	}
	set result {}
	foreach elt [lsort [send $target [list array names $var]]] {
	    append result [list set [set var]($elt) \
			   [send $target [list set [set var]($elt)]]]
	    append result "\n"
	}
	return $result
    }
    method send_filter {value} {
	return $value
    }
}

widget windows_list {
    object_include clickable_list
    param title "Windows:"
    member mode {config}
    method get_item_name {} { return window }
    method get_windows {target result_var parent} {
	upvar $result_var result
	foreach w [send $target winfo children $parent] {
	    lappend result $w
	    $self get_windows $target result $w
	}
    }
    method update {target} {
	$self list delete 0 end
	set windows {}
	$self get_windows $target windows .
	foreach w $windows {
	    $self list insert end $w
	}
    }
    method set_mode {mode} {
	set slot(mode) $mode
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
	set class [send $target winfo class $window]
	set result "# class bindings for $window\n# class: $class"
	foreach sequence [send $target bind $class] {
	    append result "\nbind $class $sequence "
	    lappend result [send $target bind $class $sequence]
	}
	append result "\n"
	return $result
    }
    method send_filter {value} {
	if [$slot(main) cget -filter_empty_window_configs] {
	    regsub -all {[ \t]*-[^ \t]+[ \t]+{}([ \t]*\\?\n?)?} $value {\1} \
		value
	}
	if [$slot(main) cget -filter_window_class_config] {
	    regsub -all "(\n)\[ \t\]*-class\[ \t\]+\[^ \\\n\]*\n?" $value \
		"\\1" value
	}
	if [$slot(main) cget -filter_window_pack_in] {
	    regsub -all "(\n)\[ \t\]*-in\[ \t\]+\[^ \\\n\]*\n?" $value \
		"\\1" value
	}
	return $value
    }
}
