#
# $Id$
#

proc tkinspect_default_options {} {
    global tkinspect_default
    option add *Scrollbar*width 12
    option add *Label*padX 0
    option add *Label*padY 0
    option add *Label*borderWidth 0
    option add *Frame.highlightThickness 0
    option add *Frame.borderWidth 2
    option add *tearOff: 0
    option add *Menubutton.borderWidth 0
    option add *Command_line.highlightThickness 0
    option add *Command_line.borderWidth 2
    option add *Tkinspect_main.highlightThickness 0
    option add *Procs_list.patterns {
	^tk[A-Z].*
	^auto_.*
    }
    option add *Globals_list.patterns {
	^tkPriv.*
	^auto_.*
	^tk_.*
    }
}
