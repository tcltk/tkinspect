#!/bin/sh
#\
exec @wish@ -f "$0" ${1+"$@"}
#
# $Id$
#

set tkinspect(counter) -1
set tkinspect(main_window_count) 0
set tkinspect(list_classes) "procs_list globals_list windows_list"
set tkinspect(help_topics) \
    "Intro Lists Procs Globals Windows Value Notes Contents"

wm withdraw .

if [file exists @tkinspect_library@/tclIndex] {
    lappend auto_path [set tkinspect_library @tkinspect_library@]
} else {
    lappend auto_path [set tkinspect_library .]
}

stl_lite_init
version_init

proc tkinspect_exit {} {
    destroy .
    exit 0
}

proc tkinspect_widgets_init {} {
    global tkinspect_library
    foreach file {
	lists.tcl procs_list.tcl globals_list.tcl windows_list.tcl
	about.tcl value.tcl help.tcl
    } {
	uplevel #0 source $tkinspect_library/$file
    }
}

proc tkinspect_about {} {
    catch {destroy .about}
    about .about
    .about run
}

dialog tkinspect_main {
    param default_lists "procs_list globals_list windows_list"
    param target ""
    member counter -1
    member get_window_info 1
    member last_list {}
    member list_counter -1
    member lists ""
    method create {} {
	global tkinspect
	$self config -highlightthickness 0 -bd 2
	pack [frame $self.menu -bd 2 -relief raised] -side top -fill x
	menubutton $self.menu.file -menu $self.menu.file.m -text "File" \
	    -underline 0
	pack $self.menu.file -side left
	set m [menu $self.menu.file.m]
	$m add cascade -label "Select Interpreter" -underline 0 \
	    -menu $self.menu.file.m.interps -command "$self fill_interp_menu"
	$m add command -label "New Window" -underline 0 \
	    -command tkinspect_create_main_window
	$m add command -label "Update Lists" -underline 0 \
	    -command "$self update_lists"
	$m add separator
	$m add command -label "Close Window" -underline 0 \
	    -command "$self close"
	$m add command -label "Exit" -underline 0 -command tkinspect_exit
	menu $self.menu.file.m.interps -tearoff 0
	menubutton $self.menu.options -menu $self.menu.options.m \
	    -text "Options" -underline 0
	pack $self.menu.options -side left
	set m [menu $self.menu.options.m]
	foreach list_class $tkinspect(list_classes) {
	    $m add command -label "New $list_class List" \
		-command "$self add_list $list_class"
	}
	$m add separator
	$m add checkbutton -variable [object_slotname get_window_info] \
            -label "Get Window Information" -underline 0
	menubutton $self.menu.help -menu $self.menu.help.m -text "Help" \
	    -underline 0
	pack $self.menu.help -side right
	set m [menu $self.menu.help.m]
	$m add command -label "About..." -command tkinspect_about \
	    -underline 0
	foreach topic $tkinspect(help_topics) {
	    $m add command -label $topic -command [list $self help $topic] \
		-underline 0
	}
	pack [set f [frame $self.buttons -bd 0]] -side top -fill x
	entry $f.command -bd 2 -relief sunken
	bind $f.command <Return> "$self send_command \[%W get\]"
	pack $f.command -side left -fill x -expand 1
	button $f.send_command -text "Send Command" \
	    -command "$self send_command \[$f.command get\]"
	button $f.send_value -text "Send Value" \
	    -command "$self.value send_value"
	pack $f.send_command $f.send_value -side left
	pack [frame $self.lists -bd 0] -side top -fill both
	value $self.value -main $self
	pack $self.value -side top -fill both -expand 1
	foreach list_class $slot(default_lists) {
	    $self add_list $list_class
	}
	pack [frame $self.status] -side top -fill x
	label $self.status.l -bd 2 -relief sunken -anchor w
	pack $self.status.l -side left -fill x -expand 1
	wm iconname $self "Tkinspect"
	wm title $self "Tkinspect: $slot(target)"
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
    method select_list_item {list item} {
	set slot(last_list) $list
	set target [$self target]
	$self.value set_value "[$list get_item_name] $item" \
	    [$list retrieve $target $item] \
	    [list $self select_list_item $list $item]
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
	if ![string length $slot(target)] {
	    tkinspect_failure \
	     "No interpreter has been selected yet.  Please select one first."
	}
	return $slot(target)
    }
    method last_list {} { return $slot(last_list) }
    method send_command {cmd} {
	set slot(last_list) ""
	set cmd [$self.buttons.command get]
	$self.value set_value [list command $cmd] [send $slot(target) $cmd] \
	    [list $self send_command $cmd]
	$self.value set_send_filter ""
	$self status "Command sent."
    }
    method add_list {list_class} {
	set list $self.lists.l[incr slot(list_counter)]
	lappend slot(lists) $list
	$list_class $list -command "$self select_list_item $list" \
	    -main $self
	pack $list -side left -fill both -expand 1
    }
    method delete_list {list} {
	set ndx [lsearch -exact $slot(lists) $list]
	set slot(lists) [lreplace $slot(lists) $ndx $ndx]
    }
    method add_menu {name} {
	set w $self.menu.[string tolower $name]
	menubutton $w -menu $w.m -text $name -underline 0
	pack $w -side left
	menu $w.m
	return $w.m
    }
    method delete_menu {name} {
	set w $self.menu.[string tolower $name]
	pack forget $w
	destroy $w
    }
    method help {topic} {
	global tkinspect tkinspect_library
	if [winfo exists $self.help] {
	    wm deiconify $self.help
	} else {
	    help_window $self.help -topics $tkinspect(help_topics) \
		-helpdir $tkinspect_library
	    center_window $self.help
	}
	$self.help show_topic $topic
    }
}

proc tkinspect_create_main_window {args} {
    global tkinspect
    set w [eval tkinspect_main .main[incr tkinspect(counter)] $args]
    incr tkinspect(main_window_count)
    return $w
}

source $tk_library/tkerror.tcl
rename tkerror tk_tkerror
proc tkinspect_failure {reason} {
    global tkinspect
    set tkinspect(error_is_failure) 1
    error $reason
}
proc tkerror {message} {
    global tkinspect errorInfo
    if [info exists tkinspect(error_is_failure)] {
	unset tkinspect(error_is_failure)
	tk_dialog .failure "Tkinspect Failure" $message warning 0 Ok
    } else {
	uplevel [list tk_tkerror $message]
    }
}

tkinspect_widgets_init
tkinspect_default_options
if [file exists ~/.tkinspect_opts] {
    source ~/.tkinspect_opts
}
tkinspect_create_main_window
