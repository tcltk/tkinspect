#
# $Id$
#

namespace eval names {
    
    namespace export names procs vars prototype value exports
    
    proc unqualify s {
        regsub -all "(^| ):+" $s {\1} result
        return $result
    }
    
    proc names {target {name ::}} {
        set result $name
        foreach n [send $target ::namespace children $name] {
            append result " " [names $target $n]
        }
        return $result
    }
    
    proc procs {target {names ""}} {
        if {$names == ""} {
            set names [names $target]
        }
        set result {}
        foreach n $names {
            foreach p [send $target ::namespace eval $n ::info procs] {
                lappend result "$n\::$p"
            }
        }
        return [unqualify $result]
    }
    
    # pinched from globals_list.tcl
    proc prototype {target proc} {
        set result {}
        set args [send $target [list ::info args $proc]]
        set defaultvar "__tkinspect:default_arg__"
        foreach arg $args {
            if [send $target [list ::info default $proc $arg $defaultvar]] {
                lappend result [list $arg [send $target \
                    [list ::set $defaultvar]]]
            } else {
                lappend result $arg
            }
        }
        
        send $target ::catch ::unset $defaultvar
        
        return [list proc [namespace tail $proc] $result {} ]
    }
    
    proc vars {target {names ""}} {
        if {$names == ""} {
            set names [names $target]
        }
        set result {}
        foreach n $names {
            foreach v [send $target ::info vars ${n}::*] {
                lappend result $v
            }
        }
        return [unqualify $result]
    }

    proc value {target var} {
        set tail [namespace tail $var]
        if {[send $target [list ::array exists $var]]} {
            return "variable $tail ; # $var is an array\n" ; # dump it out?
        }
        set cmd [list ::set $var]
        set retcode [catch [list send $target $cmd] msg]
        if {$retcode != 0} {
            return "variable $tail ; # $var not defined\n"
        } else {
            return "variable $tail \"$msg\"\n"
        }
    }
    
    proc exports {target namespace} {
        set result [send $target ::namespace eval $namespace ::namespace export]
        return [unqualify $result]
    }

    # dump [tk appname]
    proc dump appname {
        puts "names: [names $appname]"
        puts ""
        puts "procs: [procs $appname]"
        puts ""
        puts "vars: [vars $appname]"
        puts ""
        puts "exports: [exports $appname]"
    }
}

