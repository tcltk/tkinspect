#!/bin/sh
#\
exec @wish@ "$0" ${1+"$@"}
#
# $Id$
#

set tkinspect(counter) -1
set tkinspect(main_window_count) 0
set tkinspect(list_classes) {
    "procs_list Procs"
    "globals_list Globals"
    "windows_list Windows"
    "images_list Images"
    "menus_list Menus"
    "canvas_list Canvases"
}
set tkinspect(help_topics) {
    Intro Value Lists Procs Globals Windows Images Canvases Menus
    Value Miscellany Notes WhatsNew ChangeLog
}

wm withdraw .

if [file exists @tkinspect_library@/tclIndex] {
    lappend auto_path [set tkinspect_library @tkinspect_library@]
} else {
    lappend auto_path [set tkinspect_library .]
}

# Provide non-send based support using tklib's comm package.
if {![catch {package require comm}]} {
    # defer the cleanup for 2 seconds to allow other events to process
    comm::comm hook lost {after 2000 set x 1; vwait x}

    #
    # replace send with version that does both send and comm
    #
    if [string match send [info command send]] {
        rename send tk_send
    } else {
        proc tk_send args {}
    }
    proc send {app args} {
        if [string match {[0-9]*} $app] {
            eval comm::comm send [list $app] $args
        } else {
            eval tk_send [list $app] $args
        }
    }
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
	images_list.tcl about.tcl value.tcl help.tcl cmdline.tcl
	windows_info.tcl menus_list.tcl canvas_list.tcl names.tcl
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
    member last_list {}
    member lists ""
    member cmdline_counter -1
    member cmdlines ""
    member windows_info
    method create {} {
	global tkinspect
	pack [frame $self.menu -bd 2 -relief raised] -side top -fill x
	menubutton $self.menu.file -menu $self.menu.file.m -text "File" \
	    -underline 0
	pack $self.menu.file -side left
	set m [menu $self.menu.file.m]
	$m add cascade -label "Select Interpreter (send)" -underline 0 \
	    -menu $self.menu.file.m.interps
	$m add cascade -label "Select Interpreter (comm)" -underline 21 \
	    -menu $self.menu.file.m.comminterps
	$m add command -label "Connect to (comm)" -underline 0 \
	    -command "$self connect_dialog"  
	$m add command -label "Update Lists" -underline 0 \
	    -command "$self update_lists"
	$m add separator
	$m add command -label "New Tkinspect Window" -underline 0 \
	    -command tkinspect_create_main_window
	$m add command -label "New Command Line" -underline 12 \
	    -command "$self add_cmdline"
	foreach list_class $tkinspect(list_classes) {
	    $m add checkbutton -label "[lindex $list_class 1] List" \
		-variable [object_slotname [lindex $list_class 0]_is_on] \
		-command "$self toggle_list [lindex $list_class 0]"
	}	
	$m add separator
	$m add command -label "Close Window" -underline 0 \
	    -command "$self close"
	$m add command -label "Exit Tkinspect" -underline 1 \
	    -command tkinspect_exit
	menu $self.menu.file.m.interps -tearoff 0 \
	    -postcommand "$self fill_interp_menu"
	menu $self.menu.file.m.comminterps -tearoff 0 \
	    -postcommand "$self fill_comminterp_menu"
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
	label $f.cmd_label -text "Command:"
	pack $f.cmd_label -side left
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
	    set slot(${list_class}_is_on) 1
	}
	pack [frame $self.status] -side top -fill x
	label $self.status.l -bd 2 -relief sunken -anchor w
	pack $self.status.l -side left -fill x -expand 1
	set slot(windows_info) [object_new windows_info]
	wm iconname $self "Tkinspect"
	wm title $self "Tkinspect: $slot(target)"
	$self status "Ready."
    }
    method reconfig {} {
    }
    method destroy {} {
	object_delete $slot(windows_info)
    }
    method close {} {
	global tkinspect
	after 0 destroy $self
	if {[incr tkinspect(main_window_count) -1] == 0} tkinspect_exit
    }
    method set_target {target} {
	set slot(target) $target
	$self update_lists
	foreach cmdline $slot(cmdlines) {
	    $cmdline set_target $target
	}
	set name [file tail [send $target set argv0]]
	$self status "Remote interpreter is \"$target\" ($name)"
	wm title $self "Tkinspect: $target ($name)"
    }
    method update_lists {} {
	if {$slot(target) == ""} return
	$slot(windows_info) update $slot(target)
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
    method connect_dialog {} {
	if ![winfo exists $self.connect] {
	    connect_interp $self.connect -value $self
	    under_mouse $self.connect
	} else {
	    wm deiconify $self.connect
	    under_mouse $self.connect
	}
    }
    method fill_interp_menu {} {
	set m $self.menu.file.m.interps
	catch {$m delete 0 last}
	foreach interp [winfo interps] {
	    $m add command -label $interp \
		-command [list $self set_target $interp]
	}
    }
    method fill_comminterp_menu {} {
	set m $self.menu.file.m.comminterps
	catch {$m delete 0 last}
	foreach interp [comm::comm interps] {
	    if [string match [comm::comm self] $interp] {
		set label "$interp (self)"
	    } else {
		set label "$interp ([file tail [send $interp set argv0]])"
	    }
	    $m add command -label $label \
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
    method toggle_list {list_class} {
	set list $self.lists.$list_class
	if !$slot(${list_class}_is_on) {
	    $list remove
	} else {
	    $self add_list $list_class
	    if [string length $slot(target)] {
		$list update $slot(target)
	    }
	}
    }
    method add_list {list_class} {
	set list $self.lists.$list_class
	if [winfo exists $list] return
	set slot(${list_class}_is_on) 1
	lappend slot(lists) $list
	$list_class $list -command "$self select_list_item $list" \
	    -main $self
	pack $list -side left -fill both -expand 1
    }
    method delete_list {list} {
	set ndx [lsearch -exact $slot(lists) $list]
	set slot(lists) [lreplace $slot(lists) $ndx $ndx]
	pack forget $list
	# for some reason if all the lists get unpacked the
	# .lists frame doesn't collapse unless we force it
	$self.lists config -height 1
	set list_class [lindex [split $list .] 3]
	set slot(${list_class}_is_on) 0
    }
    method add_cmdline {} {
	set cmdline \
	  [command_line $self.cmdline[incr slot(cmdline_counter)] -main $self]
	$cmdline set_target $slot(target)
	lappend slot(cmdlines) $cmdline
    }
    method delete_cmdline {cmdline} {
	set ndx [lsearch -exact $slot(cmdlines) $cmdline]
	set slot(cmdlines) [lreplace $slot(cmdlines) $ndx $ndx]
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
	    raise $self.help
	} else {
	    help_window $self.help -topics $tkinspect(help_topics) \
		-helpdir $tkinspect_library
	    center_window $self.help
	}
	$self.help show_topic $topic
    }
    method windows_info {args} {
	eval $slot(windows_info) $args
    }
}

proc tkinspect_create_main_window {args} {
    global tkinspect
    set w [eval tkinspect_main .main[incr tkinspect(counter)] $args]
    incr tkinspect(main_window_count)
    return $w
}

# 971005: phealy
#
# With tk8.0 the default tkerror proc is finally gone - bgerror
# takes its place (see the changes tk8.0 changes file). This
# simplified error handling should be ok. 
#
proc tkinspect_failure {reason} {
    tk_dialog .failure "Tkinspect Failure" $reason warning 0 Ok
}

tkinspect_widgets_init
tkinspect_default_options
if [file exists ~/.tkinspect_opts] {
    source ~/.tkinspect_opts
}
tkinspect_create_main_window
if [file exists .tkinspect_init] {
    source .tkinspect_init
}

dialog connect_interp {
    param value
    method create {} {
	frame $self.top
	pack $self.top -side top -fill x
	label $self.l -text "Connect to:"
	entry $self.e -bd 2 -relief sunken
	bind $self.e <Return> "$self connect"
	pack $self.l -in $self.top -side left
	pack $self.e -in $self.top -fill x -expand 1
	button $self.close -text "Close" -command "destroy $self"
	pack $self.close -side left
	wm title $self "Connect to Interp.."
	wm iconname $self "Connect to Interp.."
	focus $self.e
    }
    method reconfig {} {
    }
    method connect {} {
	set text [$self.e get]
	if ![string match {[0-9]*} $text] return
	comm::comm connect $text
	wm withdraw $self
	$slot(value) set_target $text
    }
}
