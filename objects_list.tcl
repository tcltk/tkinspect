#
# $Id$
#
# Written by: T. Schotanus
# E-mail:     sst@bouw.tno.nl
# URL:        http://huizen.dds.nl/~quintess
#

widget object_list {
	object_include tkinspect_list
	param title "Objects"

	method get_item_name {} {
		return object
	}

	method update {target} {
		$self clear
		set objects [lsort [send $target itcl_info objects]]
		foreach object $objects {
			$self append $object
		}
	}

	method retrieve {target object} {
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

	method send_filter {value} {
		return $value
	}
}
