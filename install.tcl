#!/bin/sh
# \
exec wish "$0" ${1+"$@"}
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
	    if [catch {file mkdir $dir} msg] {
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

switch -exact -- $tcl_platform(platform) {
    unix { set prefix /usr/local }
    windows -
    macintosh { 
        set prefix [eval file join [lrange \
                [file split [info nameofexecutable]] 0 end-2]]
    }
}
set bindir \$prefix/bin
set libdir \$prefix/lib/tkinspect

install_dir .prefix -label Prefix: -variable prefix
install_dir .bindir -label "Bin dir:" -variable bindir
install_dir .libdir -label "Library dir:" -variable libdir


install_exec .wish -label "Wish executable:" -variable wish
pack .prefix .bindir .libdir .wish -side top -fill x

text .log -width 70 -height 10 -bd 4 -relief ridge -takefocus 0
pack .log -side top -fill both -expand 1

frame .buttons
pack .buttons -side top
button .install -text "Install" -command do_install
button .cancel -text "Exit" -command "destroy ."
pack .install .cancel -in .buttons -side left -padx .1c

wm title . "Tkinspect Installation"
center_window .

proc log {msg} {
    .log insert end "$msg"
    .log see end
    update
}

set wish [info nameofexecutable]

#foreach name {wish8.4 wish8.3 wish8.0 wish4.0 wish} {
#    log "Searching for $name..."
#    foreach dir [split $env(PATH) :] {
#	if [file executable [file join $dir $name]] {
#	    set wish [file join $dir $name]
#	    break
#	}
#    }
#    if ![info exists wish] {
#	log "not found!\n"
#	continue
#    }
#    break
#}
if [info exists wish] {
    log "using $wish\n"
} else {
    set wish /usr/local/bin/wish8.3
    log "Hmm, using $wish anyways...\n"
}

proc install_files {dir files} {
    global tcl_platform
    foreach file $files {
	log "Copying $file to $dir..."
	if {[catch {
            set dest [file join $dir [file tail $file]]
            file copy -force $file $dest
            switch -exact -- $tcl_platform(platform) {
                unix { file attributes $dest -permissions 0444 }
                windows -
                macintosh { file attributes $dest -readonly 1 }
                default { 
                    error "platform $tcl_platform(platform) not recognised"
                }
            }
        } errmsg]} {
	    log "whoops: $errmsg, install aborted.\n"
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
    global prefix libdir bindir wish tcl_platform
    foreach w {.prefix .bindir .libdir .wish} {
	log "Checking [$w cget -variable]..."
	if ![$w verify] {
	    log "install aborted\n"
	    return
	}
	log "ok.\n"
    }
    if ![file isdirectory [file join $libdir stl-lite]] {
	log "Making $libdir/stl-lite directory..."
	if [catch {file mkdir [file join $libdir stl-lite]} error] {
	    log "whoops: $error, install aborted.\n"
	    return
	}
	log "ok.\n"
    }
    if ![install_files $libdir {
	about.tcl defaults.tcl windows_info.tcl lists.tcl globals_list.tcl
	procs_list.tcl windows_list.tcl images_list.tcl menus_list.tcl
	canvas_list.tcl value.tcl stl.tcl sls.ppm version.tcl help.tcl
	cmdline.tcl interface.tcl tclIndex ChangeLog
	names.tcl classes_list.tcl objects_list.tcl 
        afters_list.tcl namespaces_list.tcl
	Intro.html Lists.html Procs.html Globals.html Windows.html
	Images.html Canvases.html Menus.html Classes.html
	Value.html Miscellany.html Notes.html WhatsNew.html
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
        set progname tkinspect
        if {$tcl_platform(platform) == "windows"} {
            append progname .tcl
        }
        file delete -force [file join $bindir $progname]
	set fp [open tkinspect.tcl r]
	set text [read $fp]
	close $fp
	regsub -all @tkinspect_library@ $text [regsub_quote $libdir] text
	regsub -all @wish@ $text [regsub_quote $wish] text
	set fp [open [file join $bindir $progname] w]
	puts $fp $text
	close $fp
        if {$tcl_platform(platform) == "unix"} {
            file attributes [file join $bindir $progname] -permissions 0555
        }
    } error] {
	log "whoops: $error, install aborted.\n"
	return
    }
    log "ok.\n"
    log "Install finished.\n"
}

proc do_install {} {
    toplevel .grab
    wm withdraw .grab
    while [catch {grab set .grab}] {}
    set old_focus [focus -lastfor .grab]
    focus .grab
    install
    grab release .grab
    focus $old_focus
    destroy .grab
}
