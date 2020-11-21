#
# $Id$
#
# This software is copyright (C) 1994 by the Lawrence Berkeley Laboratory.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that: (1) source code distributions
# retain the above copyright notice and this paragraph in its entirety, (2)
# distributions including binary code include the above copyright notice and
# this paragraph in its entirety in the documentation or other materials
# provided with the distribution, and (3) all advertising materials mentioning
# features or use of this software display the following acknowledgement:
# ``This product includes software developed by the University of California,
# Lawrence Berkeley Laboratory and its contributors.'' Neither the name of
# the University nor the names of its contributors may be used to endorse
# or promote products derived from this software without specific prior
# written permission.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

set object_priv(currentClass) {}
set object_priv(objectCounter) 0

proc object_class {name spec} {
    global object_priv
    set object_priv(currentClass) $name
    lappend object_priv(objects) $name
    upvar #0 ${name}_priv class
    set class(members) {}
    set class(params) {}
    eval $spec
    proc $name:config args "uplevel \[concat object_config \$args]"
    proc $name:configure args "uplevel \[concat object_config \$args]"
    proc $name:cget {self option} "uplevel \[list object_cget \$self \$option]"
}

proc method {name args body} {
    global object_priv
    set className $object_priv(currentClass)
    upvar #0 ${className}_priv class
    lappend class(methods) $name
    set methodArgs self
    append methodArgs " " $args
    proc $className:$name $methodArgs "upvar #0 \$self slot\n$body"
}

proc member {name {defaultValue {}}} {
    global object_priv
    set className $object_priv(currentClass)
    upvar #0 ${className}_priv class
    if ![info exists class(member_info/$name)] {
	lappend class(members) [list $name $defaultValue]
    }
    set class(member_info/$name) {}
}

proc param {name {defaultValue {}} {resourceClass {}} {configCode {}}} {
    global object_priv
    set className $object_priv(currentClass)
    upvar #0 ${className}_priv class
    if {$resourceClass == ""} {
	set resourceClass \
	    [string toupper [string index $name 0]][string range $name 1 end]
    }
    if ![info exists class(param_info/$name)] {
	lappend class(params) $name
    }
    set class(param_info/$name) [list $defaultValue $resourceClass]
    if {$configCode != {}} {
	proc $className:config:$name self $configCode
    }
}

proc object_include {super_class_name} {
    global object_priv
    set className $object_priv(currentClass)
    upvar #0 ${className}_priv class
    upvar #0 ${super_class_name}_priv super_class
    foreach p $super_class(params) {
	lappend class(params) $p
	set class(param_info/$p) $super_class(param_info/$p)
    }
    set class(members) [concat $super_class(members) $class(members)]
    foreach m $super_class(methods) {
	set formals {}
	set proc $super_class_name:$m
	foreach arg [info args $proc] {
	    if [info default $proc $arg def] {
		lappend formals [list $arg $def]
	    } else {
		lappend formals $arg
	    }
	}
	proc $className:$m $formals [info body $proc]
    }
}

proc object_new {className {name {}}} {
    if {$name == {}} {
	global object_priv
	set name O_[incr object_priv(objectCounter)]
    }
    upvar #0 $name object
    upvar #0 ${className}_priv class
    set object(__class) $className
    foreach var $class(params) {
	set info $class(param_info/$var)
	set resourceClass [lindex $info 1]
	if ![catch {set val [option get $name $var $resourceClass]}] {
	    if {$val == ""} {
		set val [lindex $info 0]
	    }
	} else {
	    set val [lindex $info 0]
	}
	set object($var) $val
    }
    foreach var $class(members) {
	set object([lindex $var 0]) [lindex $var 1]
    }
    proc $name {method args} [format {
	upvar #0 %s object
	uplevel [concat $object(__class):$method %s $args]
    } $name $name]
    return $name
}

proc object_define_creator {windowType name spec} {
    object_class $name $spec
    if {[info procs $name:create] == {}} {
	error "widget \"$name\" must define a create method"
    }
    if {[info procs $name:reconfig] == {}} {
	error "widget \"$name\" must define a reconfig method"
    }
    proc $name {window args} [format {
	%s $window -class %s
	rename $window object_window_of$window
	upvar #0 $window object
	set object(__window) $window
	object_new %s $window
	proc %s:frame {self args} \
	    "uplevel \[concat object_window_of$window \$args]"
	uplevel [concat $window config $args]
        if {[winfo toplevel $window] eq $window} {
            ttk::frame $window.pave
            place $window.pave -x 0 -y 0 -relwidth 1.0 -relheight 1.0
            lower $window.pave
        }
	$window create
	set object(__created) 1
	bind $window <Destroy> \
	    "if !\[string compare %%W $window\] { object_delete $window }"
	$window reconfig
	return $window
    } $windowType \
	  [string toupper [string index $name 0]][string range $name 1 end] \
	  $name $name]
}

proc widget {name spec} {
    object_define_creator ttk::frame $name $spec
}

proc dialog {name spec} {
    object_define_creator toplevel $name $spec
}

proc object_config {self args} {
    upvar #0 $self object
    set len [llength $args]
    if {$len == 0} {
	upvar #0 $object(__class)_priv class
	set result {}
	foreach param $class(params) {
	    set info $class(param_info/$param)
	    lappend result \
		[list -$param $param [lindex $info 1] [lindex $info 0] \
		 $object($param)]
	}
	if [info exists object(__window)] {
	    set result [concat $result [object_window_of$object(__window) config]]
	}
	return $result
    }
    if {$len == 1} {
	upvar #0 $object(__class)_priv class
	if {[string index $args 0] != "-"} {
	    error "param '$args' didn't start with dash"
	}
	set param [string range $args 1 end]
	if {[set ndx [lsearch -exact $class(params) $param]] == -1} {
	    if [info exists object(__window)] {
		return [object_window_of$object(__window) config -$param]
	    }
	    error "no param '$args'"
	}
	set info $class(param_info/$param)
	return [list -$param $param [lindex $info 1] [lindex $info 0] \
		$object($param)]
    }
    # accumulate commands and eval them later so that no changes will take
    # place if we find an error
    set cmds ""
    while {$args != ""} {
	set fieldId [lindex $args 0]
        if {[string index $fieldId 0] != "-"} {
            error "param '$fieldId' didn't start with dash"
        }
        set fieldId [string range $fieldId 1 end]
        if ![info exists object($fieldId)] {
	    if {[info exists object(__window)]} {
		if [catch [list object_window_of$object(__window) config -$fieldId]] {
		    error "tried to set param '$fieldId' which did not exist."
		} else {
		    lappend cmds \
			[list object_window_of$object(__window) config -$fieldId [lindex $args 1]]
		    set args [lrange $args 2 end]
		    continue
		}
	    }

        }
	if {[llength $args] == 1} {
	    return $object($fieldId)
	} else {
	    lappend cmds [list set object($fieldId) [lindex $args 1]]
	    if {[info procs $object(__class):config:$fieldId] != {}} {
		lappend cmds [list $self config:$fieldId]
	    }
	    set args [lrange $args 2 end]
	}
    }
    foreach cmd $cmds {
	eval $cmd
    }
    if {[info exists object(__created)] && [info procs $object(__class):reconfig] != {}} {
	$self reconfig
    }
}

proc object_cget {self var} {
    upvar #0 $self object
    return [lindex [object_config $self $var] 4]
}

proc object_delete self {
    upvar #0 $self object
    if {[info exists object(__class)] && [info commands $object(__class):destroy] != ""} {
	$object(__class):destroy $self
    }
    if [info exists object(__window)] {
	if [string length [info commands object_window_of$self]] {
	    catch {rename $self {}}
	    rename object_window_of$self $self
	}
	destroy $self
    }
    catch {unset object}
}

proc object_slotname slot {
    upvar self self
    return [set self]($slot)
}
