#
# $Id$
#
# Contains version numbers for tkinspect-5.
#

proc version_init {} {
    global tkinspect tk_version
    set tkinspect(release) 5.1.2
    set tkinspect(release_date) "June 16, 1995"
    scan $tk_version "%d.%d" major minor
    if {$major != 4} {
	puts stderr \
      "tkinspect-5 requires Tk 4.x, you appear to be running Tk $major.$minor"
	exit 1
    }
}

