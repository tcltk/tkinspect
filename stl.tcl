#
# $Id$
#
# Stl is my own tcl library.  It's not quite ready to be released.
# In the stl-lite directory is an extremely trimmed down version.
# This proc loads it.
#

proc stl_lite_init {} {
    global tkinspect_library
    foreach file {object.tcl filechsr.tcl simpleentry.tcl tk_util.tcl} {
	source $tkinspect_library/stl-lite/$file
    }
}
