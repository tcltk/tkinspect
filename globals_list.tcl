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
    member is_array 0
    member trace_cmd ""
    method create {} {
	scrollbar $self.sb -relief sunken -bd 1 -command "$self.t yview"
	text $self.t -yscroll "$self.sb set" -setgrid 1
	pack $self.sb -side right -fill y
	pack $self.t -side right -fill both -expand 1
	if {[send $slot(target) array size $slot(variable)] == 0} {
	    set slot(trace_cmd) "send [winfo name .] $self update_scalar"
	    $self update_scalar "" "" w
	    set slot(is_array) 0
	    set title "Trace Scalar"
	} else {
	    set slot(trace_cmd) "send [winfo name .] $self update_array"
	    set slot(is_array) 1
	    set title "Trace Array"
	}
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
    method update_scalar {name op} {
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
		[list set [set n1]([set n2]) \
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
	    $self.t delete 1.0 1.10000
	}
	$self.t see end
    }
}

proc create_variable_trace {target var} {
    global variable_trace_priv
    variable_trace .vt[incr variable_trace_priv(counter)] -target $target \
	-variable $var
}

widget globals_list {
    object_include tkinspect_list
    param title "Globals"
    method get_item_name {} { return global }
    method create {} {
	tkinspect_list:create $self
	$slot(menu) add separator
	$slot(menu) add command -label "Trace Variable" \
	    -command "$self trace_variable"
    }
    method update {target} {
	$self clear
	foreach var [lsort [send $target info globals]] {
	    $self append $var
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
    method trace_variable {} {
	set target [$slot(main) target]
	if ![string length $slot(current_item)] {
	    tkinspect_failure \
	     "No global variable has been selected.  Please select one first."
	}
	create_variable_trace $target $slot(current_item)
    }
}
