#
# $Id$
#
# Written by: T. Schotanus
# E-mail:     sst@bouw.tno.nl
# URL:        http://huizen.dds.nl/~quintess
#
# Itcl 3.2 support by Pat Thoyts <patthoyts@users.sourceforge.net>
#   We are hanging onto the older code to support old versions although
#   this needs testing.
#

widget object_list {
    object_include tkinspect_list
    param title "Objects"
    param itcl_version 0

    method get_item_name {} {
        return object
    }

    method update {target} {
        $self clear
        set cmd [list if {[::info command itcl_info] != {}} {itcl_info objects}]
        set objects [lsort [send $target $cmd]]
        if {$objects != {}} {
            set slot(itcl_version) [send $target ::package provide Itcl]
        }
        foreach object $objects {
            $self append $object
        }
    }

    method retrieve {target object} {
        if {$slot(itcl_version) != {}} {
            if {$slot(itcl_version) >= 3} {
                return [$self retrieve_new $target $object]
            } else {
                return [$self retrieve_old $target $object]
            }
        }
    }

    method retrieve_old {target object} {
        set class [send $target [list $object info class]]
        set res "$class $object {\n"
        
        set cmd [list $class :: info inherit]
        set inh [send $target $cmd]
        if {$inh != ""} {
            set res "$res\tinherit $inh\n\n"
        } else {
            set res "$res\n"
        }
        
        set pubs [send $target [list $object info public]]
        foreach arg $pubs {
            regsub {(.*)::} $arg {} a
            set cmd [list $object info public $a]
            set pub [send $target $cmd]
            set res "$res\tpublic $a [list [lindex $pub 2] [lindex $pub 3]] (default: [list [lindex $pub 1]])\n"
        }
        if {$pubs != ""} {
            set res "$res\n"
        }
        
        set prots [send $target [list $object info protected]]
        foreach arg $prots {
            regsub {(.*)::} $arg {} a
            if {$a == "this"} {
                continue
            }
            set cmd [list $object info protected $a]
            set prot [send $target $cmd]
            set res "$res\tprotected $a [list [lindex $prot 2]] (default: [list [lindex $prot 1]])\n"
        }
        if {$prots != ""} {
            set res "$res\n"
        }
        
        set coms [send $target [list $object info common]]
        foreach arg $coms {
            regsub {(.*)::} $arg {} a
            set cmd [list $object info common $a]
            set com [send $target $cmd]
            set res "$res\tcommon $a [list [lindex $com 2]] (default: [list [lindex $com 1]])\n"
        }
        if {$coms != ""} {
            set res "$res\n"
        }
        
        set meths [send $target [list $object info method]]
        foreach arg $meths {
            if {[string first $class $arg] == 0} {
                regsub {(.*)::} $arg {} a
                set cmd [list $object info method $a]
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
        
        set procs [send $target [list $object info proc]]
        foreach arg $procs {
            if {[string first $class $arg] == 0} {
                regsub {(.*)::} $arg {} a
                set cmd [list $object info proc $a]
                set proc [send $target $cmd]
                if {[lindex $proc 1] != "<built-in>"} {
                    set res "$res\tproc $a [lrange $proc 1 end]\n\n"
                }
            }
        }
        
        set res "$res}\n"
        return $res
    }
    
    method retrieve_new {target object} {
        set class [send $target [list $object info class]]
        set res "$class $object {\n"
        
        set cmd [list $object info inherit]
        set inh [send $target $cmd]
        if {$inh != ""} {
            append res "    inherit $inh\n\n"
        } else {
            append res "\n"
        }
        
        set vars [send $target $object info variable]
        foreach var $vars {
            set name [namespace tail $var]
            set cmd [list $object info variable $name]
            set text [send $target $cmd]
            append res "    $text\n"
        }
        append res "\n"
        
        
        set funcs [send $target [list $object info function]]
        foreach func [lsort $funcs] {
            set qualclass "::[string trimleft $class :]"
            if {[string first $qualclass $func] == 0} {
                set name [namespace tail $func]
                set cmd [list $object info function $name]
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
    
    method send_filter {value} {
        return $value
    }
}
