#
# $Id$
#
# Provide a uniform interface to tkinspect's actions.
#

# look for a main window
proc tkinspect_main_window {} {
    for {set i 0} {1} {incr i} {
	if [winfo exists .main$i] {
	    return .main$i
	}
    }
}

proc tkinspect_set_target {target} {
    set main [tkinspect_main_window]
    $main set_target $target
}

proc tkinspect_select {type thing} {
    set main [tkinspect_main_window]
    $main.lists.${type}s_list run_command $thing
}

proc tkinspect_create_cmdline {} {
    set main [tkinspect_main_window]
    $main add_cmdline
}

proc tkinspect_help {{topic ""}} {
    global tkinspect
    if ![string length $topic] {
	set topic [lindex $tkinspect(help_topics) 0]
    }
    set main [tkinspect_main_window]
    $main help $topic
}

proc tkinspect_value_text_window {} {
    return [tkinspect_main_window].value
}

proc tkinspect_send_value {} {
    [tkinspect_value_text_window] send_value
}

proc tkinspect_detach_value {} {
    [tkinspect_value_text_window] detach
}

proc tkinspect_trace_global {var} {
    set main [tkinspect_main_window]
    create_variable_trace $main [$main target] $var
}
