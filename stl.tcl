#
# $Id$
#
# Stl is my own tcl library.  It's not quite ready to be released.
# The stl-lite directory contains an extremely trimmed down version.
# This proc loads it.
#

proc stl_lite_init {} {
    global tkinspect_library
    foreach file {
	object.tcl filechsr.tcl simpleentry.tcl tk_util.tcl feedback.tcl
	tkhtml.tcl
    } {
	uplevel #0 [list source $tkinspect_library/stl-lite/$file]
    }
}
