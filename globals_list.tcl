#
# $Id$
#

set variable_trace_priv(counter) -1
set variable_trace_priv(trace_text) {
    send %s 
}
dialog variable_trace {
    param target ""
    param variable ""
    param width 50
    param height 5
    param savelines 50
    param main
    member is_array 0
    member trace_cmd ""
    method create {} {
	pack [frame $self.menu -bd 2 -relief raised] -side top -fill x
	menubutton $self.menu.file -text "File" -underline 0 \
	    -menu $self.menu.file.m
	pack $self.menu.file -side left
	set m [menu $self.menu.file.m]
	$m add command -label "Save Trace..." -command "$self save" \
	    -underline 0
	$m add separator
	$m add command -label "Close Window" -command "destroy $self" \
	    -underline 0
	scrollbar $self.sb -relief sunken -bd 1 -command "$self.t yview"
	text $self.t -yscroll "$self.sb set" -setgrid 1
	pack $self.sb -side right -fill y
	pack $self.t -side right -fill both -expand 1
        set where [set ::[subst $slot(main)](target,self)]
	if {![send $slot(target) array exists $slot(variable)]} {
	    set slot(trace_cmd) "send $where $self update_scalar"
	    $self update_scalar "" "" w
	    set slot(is_array) 0
	    set title "Trace Scalar"
	} else {
	    set slot(trace_cmd) "send $where $self update_array"
	    set slot(is_array) 1
	    set title "Trace Array"
	}
        $self check_remote_send
	send $slot(target) \
	    [list trace variable $slot(variable) wu $slot(trace_cmd)]
	wm title $self "$title: $slot(target)/$slot(variable)"
	wm iconname $self "$title: $slot(target)/$slot(variable)"
    }
    method reconfig {} {
	$self.t config -width $slot(width) -height $slot(height)
    }
    method destroy {} {
	send $slot(target) \
	    [list trace vdelete $slot(variable) wu $slot(trace_cmd)]
    }
    method update_scalar {args} {
	set op [lindex $args end]
	if {$op == "w"} {
	    $self.t insert end-1c \
		[list set $slot(variable) \
		 [send $slot(target) [list set $slot(variable)]]]
	} else {
	    $self.t insert end-1c [list unset $slot(variable)]
	}
	$self.t insert end-1c "\n"
	$self scroll
    }
    method update_array {args} {
	if {[set len [llength $args]] == 3} {
	    set n1 [lindex $args 0]
	    set n2 [lindex $args 1]
	    set op [lindex $args 2]
	} else {
	    set n1 [lindex $args 0]
	    set op [lindex $args 1]
	}
	if {$op == "w"} {
	    $self.t insert end-1c \
		[list set [set slot(variable)]([set n2]) \
		 [send $slot(target) [list set [set slot(variable)]([set n2])]]]
	} elseif {[info exists n2]} {
	    $self.t insert end-1c [list unset [set slot(variable)]([set n2])]
	} else {
	    $self.t insert end-1c [list unset $slot(variable)]
	}
	$self.t insert end-1c "\n"
	$self scroll
    }
    method scroll {} {
	scan [$self.t index end] "%d.%d" line col
	if {$line > $slot(savelines)} {
	    $self.t delete 1.0 2.0
	}
	$self.t see end
    }
    method save {} {
	#filechooser $self.save -title "Save $slot(variable) Trace" -newfile 1
	#set file [$self.save run]
        set file [tk_getSaveFile -title "Save $slot(variable) Trace"]
	if {![string length $file]} return
	set fp [open $file w]
	puts $fp [$self.t get 1.0 end]
	close $fp
	$slot(main) status "Trace saved to \"$file\"."
    }
    method check_remote_send {} {
        # ensure that the current target has a valid send command
        # This is commonly not the case under Windows.
        set cmd [send $slot(target) [list info commands ::send]]
        set type [set ::[subst $slot(main)](target,type)]

        # If we called in using 'comm' then even if we do have a built
        # in send we need to also support using comm.
        if {[string match $type "comm"]} {
            set script {
                if [string match ::send [info command ::send]] {
                    rename ::send ::tk_send
                }
                proc send {app args} {
                    if [string match {[0-9]*} $app] {
                        eval ::comm::comm send [list $app] $args
                    } else {
                        eval ::tk_send [list $app] $args
                    }
                }
            }
            set cmd [send $slot(target) $script]
            $slot(main) status "comm: $cmd"
        }

        if {$cmd == {}} {
            switch -exact -- $type {
                winsend {
                    set script {
                        proc ::send {app args} {
                            eval winsend send [list $app] $args
                        }
                    }
                    send $slot(target) $script
                }
                dde {
                    set script {
                        proc send {app args} {
                            eval dde eval [list $app] $args
                        }
                    }
                    send $slot(target) $script
                }
                default {
                    $slot(main) status "Target requires \"send\" command."
                }
            }
        }
        return $cmd
    }
}

proc create_variable_trace {main target var} {
    global variable_trace_priv
    variable_trace .vt[incr variable_trace_priv(counter)] -target $target \
	-variable $var -main $main
}

widget globals_list {
    object_include tkinspect_list
    param title "Globals"
    method get_item_name {} { return global }
    method create {} {
	tkinspect_list:create $self
	$slot(menu) add separator
	$slot(menu) add command -label "Trace Variable" -underline 0 \
	    -command "$self trace_variable"
    }
    method update {target} {
	$self clear
	foreach var [lsort [names::vars $target]] {
	    $self append $var
	}
    }
    method retrieve {target var} {
	if ![send $target [list array exists $var]] {
	    #return [list set $var [send $target [list set $var]]]
            set cmd [list set $var]
            set retcode [catch [list send $target $cmd] msg]
            if {$retcode != 0} {
                return "Info: $var has not been defined\n      ($msg)\n"
            } else {
                return [list set $var $msg]
            }
	}
	set result {}
        set names [lsort [send $target [list array names $var]]]
        if {[llength $names] == 0} {
            append result "array set $var {}\n"
        } else {
            foreach elt $names {
                append result [list set [set var]($elt) \
                        [send $target [list set [set var]($elt)]]]
                append result "\n"
            }
        }
	return $result
    }
    method send_filter {value} {
	return $value
    }
    method trace_variable {} {
	set target [$slot(main) target]
	if ![string length $slot(current_item)] {
	    tkinspect_failure \
	     "No global variable has been selected.  Please select one first."
	}
	create_variable_trace $slot(main) $target $slot(current_item)
    }
}
