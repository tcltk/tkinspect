#
# $Id$
#
# Provide a command line interface to an application (much of the
# code is lifted out of the Tk demo rmt).
#

dialog command_line {
    param main
    param target ""
    member executing 0
    member last_command ""
    method create {} {
	frame $self.menu -bd 2 -relief raised
	pack $self.menu -side top -fill x
	menubutton $self.menu.file -text "File" -menu $self.menu.m \
	    -underline 0 -menu $self.menu.file.m
	pack $self.menu.file -side left
	set m [menu $self.menu.file.m]
	$m add command -label "Close Window" -underline 0 \
	    -command "destroy $self"
	text $self.t -yscroll "$self.sb set"
	scrollbar $self.sb -command "$self.t yview"
	pack $self.sb -side right -fill both
	pack $self.t -side left

	# Create a binding to forward commands to the target application,
	# plus modify many of the built-in bindings so that only information
	# in the current command can be deleted (can still set the cursor
	# earlier in the text and select and insert;  just can't delete).
	bindtags $self.t "$self.t Text . all"
	bind $self.t <Return> {
	    %W mark set insert {end - 1c}
	    %W insert insert "\n"
	    regexp "(.*)\\.t$" %W dummy self
	    command_line:invoke $self
	    break
	}
	bind $self.t <Delete> {
	    if {[%W tag nextrange sel 1.0 end] != ""} {
		%W tag remove sel sel.first promptEnd
	    } else {
		if [%W compare insert < promptEnd] {
		    break
		}
	    }
	}
	bind $self.t <BackSpace> {
	    if {[%W tag nextrange sel 1.0 end] != ""} {
		%W tag remove sel sel.first promptEnd
	    } else {
		if [%W compare insert <= promptEnd] {
		    break
		}
	    }
	}
	bind $self.t <Control-d> {
	    if [%W compare insert < promptEnd] {
		break
	    }
	}
	bind $self.t <Control-k> {
	    if [%W compare insert < promptEnd] {
		%W mark set insert promptEnd
	    }
	}
	bind $self.t <Control-t> {
	    if [%W compare insert < promptEnd] {
		break
	    }
	}
	bind $self.t <Meta-d> {
	    if [%W compare insert < promptEnd] {
		break
	    }
	}
	bind $self.t <Meta-BackSpace> {
	    if [%W compare insert <= promptEnd] {
		break
	    }
	}
	bind $self.t <Control-h> {
	    if [%W compare insert <= promptEnd] {
		break
	    }
	}
	bind $self.t <Control-x> {
	    %W tag remove sel sel.first promptEnd
	}
	bind $self.t <Key> "command_line:text_insert $self %A; break"
	$self.t tag configure bold \
	    -font -*-Courier-Bold-R-Normal-*-120-*-*-*-*-*-*
	$self prompt
    }
    method destroy {} {
	$slot(main) delete_cmdline $self
    }
    method reconfig {} {
    }
    
    # The procedure below is used to print out a prompt at the
    # insertion point (which should be at the beginning of a line
    # right now).
    method prompt {} {
	$self.t insert insert "$slot(target): "
	$self.t mark set promptEnd {insert}
	$self.t mark gravity promptEnd left
	$self.t tag add bold {promptEnd linestart} promptEnd
    }

    # The procedure below executes a command (it takes everything on the
    # current line after the prompt and either sends it to the remote
    # application or executes it locally, depending on "app").
    method invoke {} {
	set cmd [$self.t get promptEnd insert]
	incr slot(executing) 1
	if [info complete $cmd] {
	    if {$cmd == "!!\n"} {
		set cmd $slot(last_command)
	    } else {
		set slot(last_command) $cmd
	    }
	    if {$slot(target) == "local"} {
		set result [catch [list uplevel #0 $cmd] msg]
	    } else {
		set result [catch [list send $slot(target) $cmd] msg]
	    }
	    if {$result != 0} {
		$self.t insert insert "Error: $msg\n"
	    } else {
		if {$msg != ""} {
		    $self.t insert insert $msg\n
		}
	    }
	    $self prompt
	    $self.t mark set promptEnd insert
	}
	incr slot(executing) -1
	$self.t yview -pickplace insert
    }

    # The following procedure is invoked to change the application that
    # we're talking to.  It also updates the prompt for the current
    # command, unless we're in the middle of executing a command from
    # the text item (in which case a new prompt is about to be output
    # so there's no need to change the old one).
    method set_target {target} {
	if ![string length $target] {
	    set target local
	}
	set slot(target) $target
	if !$slot(executing) {
	    $self.t mark gravity promptEnd right
	    $self.t delete "promptEnd linestart" promptEnd
	    $self.t insert promptEnd "$target: "
	    $self.t tag add bold "promptEnd linestart" promptEnd
	    $self.t mark gravity promptEnd left
	}
	wm title $self "Command Line: $target"
	return {}
    }

    method text_insert {s} {
	if {$s == ""} {
	    return
	}
	catch {
	    if {[$self.t compare sel.first <= insert]
		&& [$self.t compare sel.last >= insert]} {
		    $self.t tag remove sel sel.first promptEnd
		    $self.t delete sel.first sel.last
		}
	}
	$self.t insert insert $s
	$self.t see insert
    }
}
