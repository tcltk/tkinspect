#
# $Id$
#
# filechooser implements a simple file chooser.
# 
# This software is copyright (C) 1994 by the Lawrence Berkeley Laboratory.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that: (1) source code distributions
# retain the above copyright notice and this paragraph in its entirety, (2)
# distributions including binary code include the above copyright notice and
# this paragraph in its entirety in the documentation or other materials
# provided with the distribution, and (3) all advertising materials mentioning
# features or use of this software display the following acknowledgement:
# ``This product includes software developed by the University of California,
# Lawrence Berkeley Laboratory and its contributors.'' Neither the name of
# the University nor the names of its contributors may be used to endorse
# or promote products derived from this software without specific prior
# written permission.
# 
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
set filechooser_shortTypes(file) "   "
set filechooser_shortTypes(directory) DIR
set filechooser_shortTypes(characterSpecial) CHR
set filechooser_shortTypes(blockSpecial) BLK
set filechooser_shortTypes(fifo) PIP
set filechooser_shortTypes(link) LNK
set filechooser_shortTypes(socket) SOK
set filechooser_modeMap(0) x
set filechooser_modeMap(1) w
set filechooser_modeMap(2) r

option add *Filechooser*Listbox*font \
    -adobe-courier-bold-r-*-*-*-120-*-*-*-*-iso8859-*
option add *Filechooser*status1*font \
    -adobe-courier-bold-r-*-*-*-120-*-*-*-*-iso8859-*
option add *Filechooser*status2*font \
    -adobe-courier-bold-r-*-*-*-120-*-*-*-*-iso8859-*
option add *Filechooser*Listbox*geometry 45x20
    
dialog filechooser {
    param title {}
    param filter *
    param dirok 0       ;# set to 1 if open should accept directories
    param newfile 0     ;# set to 1 if new files are ok
    method create {} {
	set w $self
	wm minsize $w 100 100
	ttk::frame $w.list
	pack $w.list -in $w -side top -fill both -expand yes
	ttk::scrollbar $w.list.sb -command "$w.list.l yview"
	listbox $w.list.l -yscroll "$w.list.sb set" \
	    -exportselection false -selectmode single
	pack $w.list.sb -in $w.list -side right -fill y
	pack $w.list.l -in $w.list -side left -fill both -expand 1
	set slot(list) $w.list.l
	bind $w.list.l <Double-1> "$self open 1"
	bind $w.list.l <Button-1> [bind Listbox <Button-1>]
	foreach ev {<Button-1> <Shift-B1-Motion> <Shift-Button-1> <B1-Motion>} {
	    bind $w.list.l $ev "+$self update_selection"
	}
	set b [frame $w.bottom -bd 3 -relief ridge]
	pack $b -side top -fill both -pady 3 -padx 3
	ttk::label $b.status1 -anchor w
	ttk::label $b.status2 -anchor w
	pack $b.status1 $b.status2 -side top -fill x -padx 2
	simpleentry $b.filter -width 30 -label "Filter:"
	$b.filter bind <Return> "$self filter \[$b.filter entry get\]"
	$b.filter entry config -textvariable [object_slotname filter]
	pack $b.filter -side top -fill x -padx 5
	simpleentry $b.file -width 30 -label "File:"
	$b.file bind <Return> "$self open 1 \[$b.file entry get\]"
	pack $b.file -side top -fill x -pady 3 -padx 5
	ttk::button $b.up -command "cd ..; $self fill" -text "Up"
	ttk:button $b.open -command "$self open 0" -text "Open"
	ttk::button $b.cancel -command "object_delete $w" -text "Cancel"
	pack $b.open $b.up -in $b -side left -ipadx 5 -ipady 5 -padx 5 -pady 5
	pack $b.cancel -in $b -side right -ipadx 5 -ipady 5 -padx 5 -pady 5
    }
    method run {} {
	tkwait visibility $self
	$self fill
	set slot(result) ""
	set old_dir [pwd]
	while [catch {grab set $self}] {}
	tkwait variable [object_slotname result]
	grab release $self
	if ![info exists slot(result)] {
	    cd $old_dir
	    return ""
	}
	cd $old_dir
	after 0 [list object_delete $self]
	return $slot(result)
    }
    method reconfig {} {
	wm title $self $slot(title)
	wm iconname $self $slot(title)
    }
    method fill {} {
	global filechooser_shortTypes
	set list $slot(list)
	$list delete 0 end
	foreach f [lsort [glob -nocomplain $slot(filter)]] {
	    if [catch {file size $f} size] {
		set size 0
	    }
	    $list insert end \
	       [format "%s %6.1fk %s" $filechooser_shortTypes([file type $f]) \
		 [expr $size / 1024.0] [file tail $f]]
	}
	$self update_selection
    }
    method filter {filter} {
	set slot(filter) $filter
	$self fill
    }
    method get_selection {} {
	set l $slot(list)
	set sel [$l curselection]
	if {$sel == {}} return
	set file [$l get $sel]
	if {[llength $file] == 2} {
	    set file [lindex $file 1]
	} else {
	    set file [lindex $file 2]
	}
	return $file
    }
    method update_selection {} {
	$self.bottom.file entry delete 0 end
	set f [$self get_selection]
	$self.bottom.file entry insert 0 [pwd]/$f
	if [string length $f] {
	    global filechooser_shortTypes filechooser_modeMap
	    file lstat $f stat
	    for {set bit 8} {$bit >= 0} {incr bit -1} {
		if {$stat(mode) & (1 << $bit)} {
		    append mode $filechooser_modeMap([expr $bit % 3])
		} else {
		    append mode -
		}
	    }
	    set msg1 \
		[format "%s %6.1fk %s %5d %5d" \
		 $filechooser_shortTypes($stat(type)) \
		 [expr $stat(size) / 1024.0] $mode $stat(gid) $stat(uid)]
	    set msg2 [file tail $f]
	    if {$stat(type) == "link"} {
		append msg2 " -> [file readlink $f]"
	    }
	} else {
	    set msg1 ""
	    set msg2 ""
	}
	$self.bottom.status1 config -text $msg1
	$self.bottom.status2 config -text $msg2
    }
    method open {is_click {file ""}} {
	if ![string length $file] {
	    set file [$self get_selection]
	}
	if {$slot(newfile) && ![file exists $file]} {
	    set slot(result) $file
	    return
	}
	if {($is_click || !$slot(dirok)) && [file isdirectory $file]} {
	    cd $file
	    $self fill
	    return
	}
	set slot(result) $file
    }
}
