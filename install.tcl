#!/usr/local/bin/wish -f
#
# $Id$
#
# Installation script for Tkinspect release 5.  To install:
#
# 1. Go to the tkinspect source directory.
# 2. Type: wish -f install.tcl.
# 3. Fill out the form.
# 4. Hit the install button.  If all goes well, the last line in
#    the log window should be "Installed finished."
#

if ![file exists tclIndex] {
    puts "Generating auto loader index..."
    auto_mkindex . *.tcl
}

set tkinspect_library .
lappend auto_path .

version_init
stl_lite_init

widget install_path {
    param label
    param variable
    method create {} {
	entry $self.e -width 60 -bd 2 -relief sunken
	label $self.l
	pack $self.e -side right
	pack $self.l -side left
    }
    method reconfig {} {
	$self.l config -text $slot(label)
	$self.e config -textvariable $slot(variable)
    }
}

widget install_dir {
    object_include install_path
    method verify {} {
	upvar #0 $slot(variable) dir
	set dir [uplevel #0 [list subst $dir]]
	if ![file exists $dir] {
	    set ans [tk_dialog .mkdir "Create Directory?" "The directroy $dir does not exists, should I create it?" question 0 "Yes" "Cancel Install"]
	    if {$ans == 1} {
		return 0
	    }
	    if [catch {exec mkdir $dir} msg] {
		tk_dialog .error "Error Making Directory" "Couldn't make directory $dir: $msg" error 0 "Ok"
		return 0
	    }
	}
	return 1
    }
}

widget install_exec {
    object_include install_path
    method verify {} {
	upvar #0 $slot(variable) file
	set file [uplevel #0 [list subst $file]]
	if ![file executable $file] {
	    tk_dialog .error "Error" "Executable $file isn't executable!" error 0 "Ok"
	    return 0
	}
	return 1
    }
}

label .title -text "Tkinspect Installation" \
    -font -adobe-helvetica-bold-r-*-*-*-180-*-*-*-*-*-*
label .title2 -text "Release $tkinspect(release) ($tkinspect(release_date))" \
    -font -*-helvetica-medium-r-*-*-12-*
pack .title .title2 -side top

text .instructions -relief ridge -bd 4 -width 20 -height 4 -wrap word \
    -takefocus 0
.instructions insert 1.0 \
{Fill out the pathnames below and press the install button.  Any errors will appear in log window below.  If you wish to demo tkinspect w/o installing it, try "wish -f tkinspect.tcl".
}
pack .instructions -side top -fill both -expand 1
set prefix /usr/local
install_dir .prefix -label Prefix: -variable prefix
set bindir \$prefix/bin
install_dir .bindir -label "Bin dir:" -variable bindir
set libdir \$prefix/lib/tkinspect
install_dir .libdir -label "Library dir:" -variable libdir
set wish /usr/local/bin/wish
install_exec .wish -label "Wish executable:" -variable wish
pack .prefix .bindir .libdir .wish -side top -fill x

text .log -width 70 -height 10 -bd 4 -relief ridge -takefocus 0
pack .log -side top -fill both -expand 1

frame .buttons
pack .buttons -side top
button .install -text "Install" -command install
button .cancel -text "Exit" -command "destroy ."
pack .install .cancel -in .buttons -side left -padx .1c

wm title . "Tkinspect Installation"
center_window .

proc log {msg} {
    .log insert end "$msg"
    .log see end
    update idletasks
}

proc install_files {dir files} {
    foreach file $files {
	log "Copying $file to $dir..."
	if {[catch {exec rm -f $dir/[file tail $file]}] || [catch {exec cp $file $dir} error] || [catch {exec chmod 0444 $dir/[file tail $file]} error]} {
	    log "whoops: $error, install aborted.\n"
	    return 0
	}
	log "ok.\n"
    }
    return 1
}

proc regsub_quote {string} {
    regsub -all {\\([0-9])} $string {\\\\\1} string
    regsub -all "&" $string {\\&} string
    return $string
}

proc install {} {
    global prefix libdir bindir wish
    foreach w {.prefix .bindir .libdir .wish} {
	log "Checking [$w cget -variable]..."
	if ![$w verify] {
	    log "install aborted\n"
	    return
	}
	log "ok.\n"
    }
    if ![file isdirectory $libdir/stl-lite] {
	log "Making $libdir/stl-lite directory..."
	if [catch {exec mkdir $libdir/stl-lite} error] {
	    log "whoops: $error, install aborted.\n"
	    return
	}
	log "ok.\n"
    }
    if ![install_files $libdir {
	about.tcl defaults.tcl lists.tcl globals_list.tcl procs_list.tcl
	windows_list.tcl value.tcl stl.tcl sls.xbm version.tcl
	help.tcl cmdline.tcl interface.tcl tclIndex
	Intro.html Lists.html Procs.html Globals.html Windows.html
	Value.html Miscellany.html Notes.html WhatsNew.html ChangeLog.html
    }] {
	return
    }

    if ![install_files $libdir/stl-lite {
	stl-lite/filechsr.tcl stl-lite/simpleentry.tcl stl-lite/object.tcl
	stl-lite/tk_util.tcl stl-lite/feedback.tcl stl-lite/tkhtml.tcl
    }] {
	return
    }
    log "Making tkinspect shell script..."
    if [catch {
	exec rm -f $bindir/tkinspect
	set fp [open tkinspect.tcl r]
	set text [read $fp]
	close $fp
	regsub -all @tkinspect_library@ $text [regsub_quote $libdir] text
	regsub -all @wish@ $text [regsub_quote $wish] text
	set fp [open $bindir/tkinspect w]
	puts $fp $text
	close $fp
	exec chmod 0555 $bindir/tkinspect
    } error] {
	log "whoops: $error, install aborted.\n"
	return
    }
    log "ok.\n"
    log "Install finished.\n"
}
