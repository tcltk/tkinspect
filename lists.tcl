#
# $Id$
#

dialog filter_editor {
    param list
    member patterns
    member filter_type exclude
    method create {} {
        frame $self.top
        label $self.l -text "Pattern:"
        entry $self.e -width 40 -relief sunken
	bind $self.e <Return> "$self add_pattern"
        pack $self.l -in $self.top -side left
        pack $self.e -in $self.top -side left -fill x
        pack $self.top -side top -fill x -pady .25c
        frame $self.buttons -bd 3
        button $self.ok -text "Apply" -command "$self apply"
        button $self.close -text "Cancel" -command "wm withdraw $self"
        button $self.add -text "Add Pattern" \
	    -command "$self add_pattern"
        button $self.del -text "Delete Pattern(s)" \
	    -command "$self delete_patterns"
        radiobutton $self.inc -variable [object_slotname filter_type] \
	    -value include -relief flat -text "Include Patterns"
        radiobutton $self.exc -variable [object_slotname filter_type] \
	    -value exclude -relief flat -text "Exclude Patterns"
        pack $self.inc $self.exc $self.add $self.del -in $self.buttons \
	    -side top -fill x -pady .1c -anchor w
        pack $self.close $self.ok -in $self.buttons \
	    -side bottom -fill x -pady .1c
        pack $self.buttons -in $self -side left -fill y
        frame $self.lframe
        scrollbar $self.sb -command "$self.list yview"
        listbox $self.list -yscroll "$self.sb set" -relief raised \
            -width 40 -height 10 -selectmode multiple
        pack $self.sb -in $self.lframe -side right -fill y
        pack $self.list -in $self.lframe -side right -fill both -expand yes
        pack $self.lframe -in $self -side right -fill both -expand yes
	set title "Edit [$slot(list) cget -title] Filter"
	wm title $self $title
	foreach pat [$slot(list) cget -patterns] {
	    $self.list insert end $pat
	    lappend slot(patterns) $pat
	}
    }
    method reconfig {} {
    }
    method apply {} {
	$slot(list) config -patterns $slot(patterns) \
	    -filter_type $slot(filter_type)
	$slot(list) update_needed
	wm withdraw $self
    }
    method add_pattern {} {
	set pat [$self.e get]
	if {[string length $pat]} {
	    lappend slot(patterns) $pat
	    $self.list insert end $pat
	}
    }
    method delete_patterns {} {
	while {[string length [set s [$self.list curselection]]]} {
	    set pat [$self.list get [lindex $s 0]]
	    set ndx [lsearch -exact $slot(patterns) $pat]
	    set slot(patterns) [lreplace $slot(patterns) $ndx $ndx]
	    $self.list delete [lindex $s 0]
	}
    }
}

dialog list_search {
    param list
    param search_type exact
    method create {} {
	frame $self.top
	pack $self.top -side top -fill x
	label $self.l -text "Search for:"
	entry $self.e -bd 2 -relief sunken
	bind $self.e <Return> "$self search"
	pack $self.l -in $self.top -side left
	pack $self.e -in $self.top -fill x -expand 1
	checkbutton $self.re -variable [object_slotname search_type] \
	    -onvalue regexp -offvalue exact -text "Regexp search"
	pack $self.re -side top -anchor w
	button $self.go -text "Find Next" -command "$self search"
	button $self.reset -text "Reset Search" -command "$self reset"
	button $self.close -text "Close" -command "destroy $self"
	pack $self.go $self.reset $self.close -side left
	set title "Find in [$slot(list) get_item_name] List..."
	wm title $self $title
	focus $self.e
	$slot(list) reset_search
    }
    method reconfig {} {
    }
    method reset {} {
	$slot(list) reset_search 1
    }
    method search {} {
	set text [$self.e get]
	if ![string length $text] return
	$slot(list) search $slot(search_type) $text
    }
}

dialog list_show {
    param list
    method create {} {
	frame $self.top
	pack $self.top -side top -fill x
	label $self.l -text "Show:"
	entry $self.e -bd 2 -relief sunken
	bind $self.e <Return> "$self show"
	pack $self.l -in $self.top -side left
	pack $self.e -in $self.top -fill x -expand 1
	button $self.show -text "Show" -command "$self show"
	button $self.close -text "Close" -command "destroy $self"
	pack $self.show $self.close -side left
	wm title $self "Show a [$slot(list) get_item_name]"
	focus $self.e
    }
    method reconfig {} {
    }
    method show {} {
	set item [$self.e get]
	$slot(list) run_command $item
	wm withdraw $self
    }
}

widget tkinspect_list {
    param command {}
    param title {}
    param width 15
    param height 12
    param main
    param patterns {}
    param filter_type exclude
    member current_item
    member menu
    member contents {}
    member search_index 0
    method create {} {
	$self config -bd 2 -relief raised
	pack [label $self.title -anchor w] -side top -fill x
	scrollbar $self.sb -command "$self.list yview" -relief sunken -bd 1
	listbox $self.list -relief sunken -exportselection 0 \
	    -yscroll "$self.sb set" -selectmode single
	bind $self.list <1> "$self click %x %y; continue"
	bind $self.list <Key-space> "$self trigger; continue"
	pack $self.sb -side right -fill y
	pack $self.list -side right -fill both -expand yes
	set slot(menu) [$slot(main) add_menu $slot(title)]
	bind $self.list <3> "tk_popup $slot(menu) %X %Y"
	$slot(menu) add command \
	    -label "Show a [$self get_item_name]..." -underline 0 \
	    -command "$self show_dialog"
	$slot(menu) add command -label "Find $slot(title)..." -underline 0 \
	    -command "$self search_dialog"
	$slot(menu) add command -label "Edit Filter..." -underline 0 \
	    -command "$self edit_filter"
	$slot(menu) add command -label "Update This List" -underline 0 \
	    -command "$self do_update_self"
    }
    method reconfig {} {
	$self.title config -text "$slot(title):"
	$self.list config -width $slot(width) -height $slot(height)
    }
    method clear {} {
	set slot(contents) ""
    }
    method append {item} {
	lappend slot(contents) $item
	$self update_needed
    }
    method update_needed {} {
	if ![info exists slot(update_pending)] {
	    set slot(update_pending) 1
	    after 0 $self do_update
	}	
    }
    method do_update {} {
	unset slot(update_pending)
	$self.list delete 0 end
	if {$slot(filter_type) == "exclude"} {
	    set x 1
	} else {
	    set x 0
	}
	foreach item $slot(contents) {
	    set include $x
	    foreach pattern $slot(patterns) {
		if [regexp -- $pattern $item] {
		    set include [expr !$x]
		    break
		}
	    }
	    if $include {
		$self.list insert end $item
	    }
	}
    }
    # lists will have 2 methods, update and update_self.  update will
    # be called when all the lists are updated.  update_self will be
    # called when just this list is updated.  update_self defaults
    # to being just update.
    method update_self {target} { $self update $target }
    method do_update_self {} { $self update_self [$slot(main) target] }
    method click {x y} {
	$self run_command [$self.list get @$x,$y]
    }
    method trigger {} {
	set selection [$self.list curselection]
	if ![llength $selection] return
	$self run_command [$self.list get [lindex $selection 0]]
    }
    method run_command {item} {
	if [string length $slot(command)] {
	    set slot(current_item) $item
	    if [string length $slot(current_item)] {
		uplevel #0 [concat $slot(command) $slot(current_item)]
	    }
	}	
    }
    method remove {} {
	$slot(main) delete_menu $slot(title)
	$slot(main) delete_list $self
	object_delete $self
    }
    method edit_filter {} {
	if [winfo exists $self.editor] {
	    wm deiconify $self.editor
	} else {
	    filter_editor $self.editor -list $self
	    center_window $self.editor
	}
    }
    method search_dialog {} {
	if ![winfo exists $self.search] {
	    list_search $self.search -list $self
	    center_window $self.search
	} else {
	    wm deiconify $self.search
	}
    }
    method reset_search {{set_see 0}} {
	set slot(search_index) 0
	if $set_see {
	    $self.list see 0
	}
    }
    method search {search_type text} {
	foreach item [$self.list get $slot(search_index) end] {
	    set found 0
	    if {$search_type == "regexp" && [regexp $text $item]} {
		set found 1
	    } elseif {[string first $text $item] != -1} {
		set found 1
	    }
	    if $found {
		$self.list selection clear 0 end
		$self.list selection set $slot(search_index)
		$self.list see $slot(search_index)
		incr slot(search_index)
		$self run_command $item
		break
	    }
	    incr slot(search_index)
	}
	if !$found {
	    $slot(main) status "Didn't find \"$text\""
	    $self reset_search
	}
    }
    method show_dialog {} {
	if ![winfo exists $self.show] {
	    list_show $self.show -list $self
	    center_window $self.show
	} else {
	    wm deiconify $self.show
	}
    }
}
