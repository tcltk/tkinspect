#
# $Id$
#
# Written by: T. Schotanus
# E-mail:     sst@bouw.tno.nl
# URL:        http://huizen.dds.nl/~quintess
#
# Itcl 3.2 support by Pat Thoyts <patthoyts@users.sourceforge.net>
#   The original code is renamed to base_class_list and if a newer
#   version of incr Tcl is found then we shall override some methods.
#

widget base_class_list {
    object_include tkinspect_list
    param title "Classes"
    
    method get_item_name {} {
        return class
    }
    
    method update {target} {
        $self clear
        set classes [lsort [send $target itcl_info classes]]
        foreach class $classes {
            $self append $class
        }
    }
    
    method retrieve {target class} {
        set res "itcl_class $class {\n"
        
        set cmd [list $class :: info inherit]
        set inh [send $target $cmd]
        if {$inh != ""} {
            set res "$res\tinherit $inh\n\n"
        } else {
            set res "$res\n"
        }
        
        set pubs [send $target [list $class :: info public]]
        foreach arg $pubs {
            regsub {(.*)::} $arg {} a
            set res "$res\tpublic $a\n"
        }
        if {$pubs != ""} {
            set res "$res\n"
        }
        
        set prots [send $target [list $class :: info protected]]
        foreach arg $prots {
            regsub {(.*)::} $arg {} a
            if {$a != "this"} {
                set res "$res\tprotected $a\n"
            }
        }
        if {$prots != ""} {
            set res "$res\n"
        }
        
        set coms [send $target [list $class :: info common]]
        foreach arg $coms {
            regsub {(.*)::} $arg {} a
            set cmd [list $class :: info common $a]
            set com [send $target $cmd]
            set res "$res\tcommon $a [list [lindex $com 2]] (default: [list [lindex $com 1]])\n"
        }
        if {$coms != ""} {
            set res "$res\n"
        }
        
        set meths [send $target [list $class :: info method]]
        foreach arg $meths {
            if {[string first $class $arg] == 0} {
                regsub {(.*)::} $arg {} a
                set cmd [list $class :: info method $a]
                set meth [send $target $cmd]
                if {$a != "constructor" && $a != "destructor"} {
                    set nm "method "
                } else {
                    set nm ""
                }
                if {[lindex $meth 1] != "<built-in>"} {
                    set res "$res\t$nm$a [lrange $meth 1 end]\n\n"
                }
            }
        }
        
        set procs [send $target [list $class :: info proc]]
        foreach arg $procs {
            if {[string first $class $arg] == 0} {
                regsub {(.*)::} $arg {} a
                set cmd [list $class :: info proc $a]
                set proc [send $target $cmd]
                if {[lindex $proc 1] != "<built-in>"} {
                    set res "$res\tproc $a [lrange $proc 1 end]\n\n"
                }
            }
        }
        
        set res "$res}\n"
        return $res
    }
    
    method send_filter {value} {
        return $value
    }
}

# -------------------------------------------------------------------------
# Handle new versions of incr Tcl
# -------------------------------------------------------------------------

if {[catch {package versions Itcl} itcl_version]} {
    set itcl_version 0
}

if {$itcl_version < 3.2} {

    # Older incr Tcl versions

    widget class_list {
        object_include tkinspect_list
        object_include base_class_list
    }

} else {

    # incr Tcl 3.2+

    widget class_list {
        object_include tkinspect_list
        object_include base_class_list
        
        method retrieve {target class} {
            set res "itcl::class $class {\n"
            
            set cmd [list namespace eval $class {info inherit}]
            set inh [send $target $cmd]
            if {$inh != ""} {
                append res "    inherit $inh\n\n"
            } else {
                append res "\n"
            }
            
            set vars [send $target namespace eval $class {info variable}]
            foreach var $vars {
                set name [namespace tail $var]
                set cmd [list namespace eval $class \
                             [list info variable $name -protection -type -name -init]]
                set text [send $target $cmd]
                append res "    $text\n"
            }
            append res "\n"
            
            
            set funcs [send $target [list namespace eval $class {info function}]]
            foreach func [lsort $funcs] {
                set qualclass "::[string trimleft $class :]"
                if {[string first $qualclass $func] == 0} {
                    set name [namespace tail $func]
                    set cmd [list namespace eval $class [list info function $name]]
                    set text [send $target $cmd]

                    if {![string match "@itcl-builtin*" [lindex $text 4]]} {
                        switch -exact -- $name {
                            constructor {
                                append res "    $name [lrange $text 3 end]\n"
                            }
                            destructor {
                                append res "    $name [lrange $text 4 end]\n"
                            }
                            default {
                                append res "    [lindex $text 0] [lindex $text 1] $name\
                                 [lrange $text 3 end]\n"
                            }
                        }
                    }
                }
            }
            
            append res "}\n"
            return $res
        }
    }

}