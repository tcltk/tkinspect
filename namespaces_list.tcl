# namespaces_list.tcl - Originally written by Paul Healy <ei9gl@indigo.ie>
#
# $Id$

widget namespaces_list {
    object_include tkinspect_list
    param title "Namespaces"
    method get_item_name {} { return namespace }
    method update {target} {
	$self clear
        foreach namespace [names::names $target] {
            $self append $namespace
        }
    }
    method retrieve {target namespace} {
        set result "namespace eval $namespace {\n"
        
        set exports [names::exports $target $namespace]
        if {$exports!=""} {
            append result "\n   namespace export $exports\n"
        }
        
        set vars [names::vars $target $namespace]
        if {$vars!=""} {
            append result "\n"
        }
        foreach var [lsort $vars] {
            append result "   [names::value $target $var]"
        }

        set procs [lsort [names::procs $target $namespace]]
        append result "\n# export:\n"
        foreach proc $procs {
            if {[lsearch -exact $exports [namespace tail $proc]]!=-1} {
                append result "   [names::prototype $target $proc]\n"  
            }
        }
        append result "\n# internal:\n"
        foreach proc $procs {
            if {[lsearch -exact $exports [namespace tail $proc]]==-1} {
                append result "   [names::prototype $target $proc]\n"  
            }
        }

        append result "}\n\n"

        set children [names::names $target $namespace]
        foreach child [lsort $children] {
            if {$child!=$namespace} {
                append result "namespace eval $child {}\n"
            }
        }

	return $result
    }
    method send_filter {value} {
	return $value
    }
}
