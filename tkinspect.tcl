#!@wish@ -f
#
# $Id$
#

set tkinspect(counter) -1
set tkinspect(main_window_count) 0
set tkinspect(release) 5alpha
set tkinspect(release_date) "Feb 6, 1995"

wm withdraw .

if [file exists @stl_library@/tclIndex] {
    lappend auto_path @stl_library@
} else {
    lappend auto_path /usr/local/lib/stl
    lappend auto_path /vol/pub/stl-0.2/lib/stl
}

if [file exists @tkinspect_library@/tclIndex] {
    lappend auto_path [set tkinspect_library @tkinspect_library@]
} else {
    lappend auto_path [set tkinspect_library .]
}


proc tkinspect_exit {} {
    destroy .
    exit 0
}

proc tkinspect_widgets_init {} {
    global tkinspect_library
    foreach file {lists.tcl about.tcl value.tcl} {
	source $tkinspect_library/$file
    }
}

proc tkinspect_about {} {
    catch {destroy .about}
    about .about
    .about run
}

dialog tkinspect_main {
    member lists {}
    member counter -1
    member target
    member window_info_type config
    member last_list
    member last_item
    param filter_empty_window_configs 1
    param get_window_info 1
    param filter_window_class_config 1
    param filter_window_pack_in 1
    method create {} {
	global tkinspect_default
	$self config -highlightthickness 0 -bd 2
	pack [frame $self.menu -bd 2 -relief raised] -side top -fill x
	menubutton $self.menu.file -menu $self.menu.file.m -text "File" \
	    -bd 0
	pack $self.menu.file -side left
	set m [menu $self.menu.file.m]
	$m add cascade -label "Select Interpreter" \
	    -menu $self.menu.file.m.interps -command "$self fill_interp_menu"
	$m add command -label "New Window" -command create_main_window
	$m add command -label "Update Lists" -command "$self update_lists"
	$m add separator
	$m add command -label "Close Window" -command "$self close"
	$m add command -label "Exit" -command tkinspect_exit
	menu $self.menu.file.m.interps -tearoff 0
	menubutton $self.menu.options -menu $self.menu.options.m \
	    -text "Options" -bd 0
	set m [menu $self.menu.options.m]
	$m add radiobutton -variable [object_slotname window_info_type] \
	    -value config -label "Window Configuration" -underline 7 \
            -command "$self change_window_info_type"
        $m add radiobutton -variable [object_slotname window_info_type] \
	    -value packing -label "Window Packing" -underline 7 \
            -command "$self change_window_info_type"
        $m add radiobutton -variable [object_slotname window_info_type] \
	    -value slavepacking -label "Slave Window Packing" -underline 1 \
            -command "$self change_window_info_type"
        $m add radiobutton -variable [object_slotname window_info_type] \
	    -value bindings -label "Window Bindings" -underline 7 \
            -command "$self change_window_info_type"
        $m add radiobutton -variable [object_slotname window_info_type] \
	    -value classbindings -label "Window Class Bindings" -underline 8 \
            -command "$self change_window_info_type"
        $m add separator
        $m add checkbutton \
	    -variable [object_slotname filter_empty_window_configs] \
            -label "Filter Empty Window Options" -underline 0
        $m add checkbutton \
	    -variable [object_slotname filter_window_class_config] \
            -label "Filter Window -class Options" -underline 0
        $m add checkbutton \
	    -variable [object_slotname filter_window_pack_in] \
            -label "Filter Pack -in Options" -underline 0
        $m add checkbutton \
	    -variable [object_slotname get_window_info] \
            -label "Get Window Information" -underline 0
	pack $self.menu.options -side left
	menubutton $self.menu.help -menu $self.menu.help.m -text "Help" \
	    -bd 0
	pack $self.menu.help -side right
	set m [menu $self.menu.help.m]
	$m add command -label "About..." -command tkinspect_about
	pack [set f [frame $self.buttons -bd 0]] -side top -fill x
	entry $f.command -bd 2 -relief sunken
	bind $f.command <Return> "$self send_command \[%W get\]"
	pack $f.command -side left -fill x -expand 1
	button $f.send_command -text "Send Command" \
	    -command "$self send_command"
	button $f.send_value -text "Send Value" \
	    -command "$self.value send_value"
	pack $f.send_command $f.send_value -side left
	pack [frame $self.lists -bd 0] -side top -fill both -expand 1
	set slot(lists) ""
	set i -1
	foreach list_class $tkinspect_default(lists) {
	    set list $self.lists.l[incr i]
	    $list_class $list -command "$self list_item_click $list" \
		-main $self
	    lappend slot(lists) $list
	    pack $list -side left -fill y -expand 1
	}
	value $self.value -main $self
	pack $self.value -side top -fill both -expand 1
	pack [frame $self.status] -side top -fill x
	label $self.status.l -bd 2 -relief sunken -anchor w
	pack $self.status.l -side left -fill x -expand 1
	wm iconname $self "Tkinspect"
	wm title $self "Tkinspect:"
	$self status "Ready."
    }
    method reconfig {} {
    }
    method close {} {
	global tkinspect
	after 0 destroy $self
	if {[incr tkinspect(main_window_count) -1] == 0} tkinspect_exit
    }
    method set_target {target} {
	set slot(target) $target
	$self update_lists
	$self status "Remote interpreter is \"$target\""
	wm title $self "Tkinspect: $target"
    }
    method update_lists {} {
	if {$slot(target) == ""} return
	foreach list $slot(lists) {
	    $list update $slot(target)
	}
    }
    method change_window_info_type {} {
	foreach list $slot(lists) {
	    if {[$list cget -class] == "Windows_list"} {
		$list set_mode $slot(window_info_type)
		if {$slot(last_list) == $list} {
		    $self list_item_click $list $slot(last_item)
		}
	    }
	}
    }
    method list_item_click {list item} {
	set slot(last_item) $item
	set slot(last_list) $list
	$self.value set_value "[$list get_item_name] $item" \
	    [$list retrieve $slot(target) $item] \
	    [list $self list_item_click $list $item]
	$self.value set_send_filter [list $list send_filter]
	$self status "Showing \"$item\""
    }
    method fill_interp_menu {} {
	set m $self.menu.file.m.interps
	catch {$m delete 0 last}
	foreach interp [winfo interps] {
	    $m add command -label $interp \
		-command [list $self set_target $interp]
	}
    }
    method status {msg} {
	$self.status.l config -text $msg
    }
    method target {} {
	return $slot(target)
    }
    method send_command {cmd} {
	set slot(last_list) ""
	set slot(last_item) ""
	set cmd [$self.buttons.command get]
	$self.value set_value [list command $cmd] [send $slot(target) $cmd] \
	    [list $self send_command $cmd]
	$self.value set_send_filter ""
	$self status "Command sent."
    }
}

proc create_main_window {} {
    global tkinspect
    tkinspect_main .main[incr tkinspect(counter)]
    incr tkinspect(main_window_count)
}

widgets_init
tkinspect_widgets_init
tkinspect_default_options
if [file exists ~/.tkinspect_opts] {
    source ~/.tkinspect_opts
}
create_main_window
