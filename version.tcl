#
# $Id$
#
# Contains version numbers for tkinspect-5.
#

proc version_init {} {
    global tkinspect tk_version tk_patchLevel
    set tkinspect(release) 5.1.6p3
    set tkinspect(release_date) "Nov 23, 1997"
    scan $tk_version "%d.%d" major minor
    if {$major < 8} {
	puts stderr \
      "tkinspect-5.1.6.p3 requires Tk 8.x, you appear to be running Tk $major.$minor"
	exit 1
    }
    if {[scan $tk_patchLevel "4.0b%d" beta] == 1 && $beta < 4} {
	tk_dialog .warning "Warning!" \
"tkinspect-$tkinspect(release) has only been tested on 4.0b4.  You might have problems running on $tk_patchLevel." warning 0 Ok
    }
}

