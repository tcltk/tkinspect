#
# $Id$
#
# Contains version numbers for tkinspect-5.
#

proc version_init {} {
    global tkinspect tk_version tk_patchLevel
    set tkinspect(release) 5.1.3
    set tkinspect(release_date) "June 21, 1995"
    scan $tk_version "%d.%d" major minor
    if {$major != 4} {
	puts stderr \
      "tkinspect-5 requires Tk 4.x, you appear to be running Tk $major.$minor"
	exit 1
    }
    if {[scan $tk_patchLevel "4.0b%d" beta] == 1 && $beta < 4} {
	tk_dialog .warning "Warning!" \
"tkinspect-$tkinspect(release) has only been tested on 4.0b4.  You might have problems running on $tk_patchLevel." warning 0 Ok
    }
}

