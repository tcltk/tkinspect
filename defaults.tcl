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
    option add *Value*vname*font \
	-adobe-courier-medium-r-*-*-*-130-*-*-*-*-iso8859-*
    option add *Text*font \
	-adobe-courier-medium-r-*-*-*-130-*-*-*-*-iso8859-*
    option add *Tkinspect_main*Menubutton.borderWidth 0
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
