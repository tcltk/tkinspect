#
# $Id$
#

namespace eval names {

   namespace export names procs vars

   proc unqualify s {
      regsub -all "(^| ):+" $s {\1} result
      return $result
   }

   proc names {target {name ::}} {
      set result $name
      foreach n [send $target namespace children $name] {
         append result " " [names $target $n]
      }
      return $result
   }

   proc procs target {
      set result {}
      foreach n [names $target] {
         foreach p [send $target namespace eval $n ::info procs] {
            lappend result "$n\::$p"
         }
      }
      return [unqualify $result]
   }

   proc vars target {
      set result {}
      foreach n [names $target] {
         foreach v [send $target ::info vars ${n}::*] {
            lappend result $v
         }
      }
      return [unqualify $result]
   }

# dump [tk appname]

   proc dump appname {
      puts "names: [names $appname]"
      puts ""
      puts "procs: [procs $appname]"
      puts ""
      puts "vars: [vars $appname]"
   }
}

