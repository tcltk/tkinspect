#
# $Id$
#
# Handle the about box.
#

dialog about {
    param obliqueFont -*-helvetica-medium-o-*-*-12-* Font
    param font -*-helvetica-medium-r-*-*-12-* Font
    param boldFont -*-helvetica-bold-r-*-*-18-* Font
    method create {} {
	global tkinspect tkinspect_library
	wm withdraw $self
	wm transient $self .
	pack [ttk::frame $self.border] -expand 1 -fill both
	ttk::label $self.title -text "tkinspect" -font $slot(boldFont)
	ttk::label $self.ver \
	    -text "Release $tkinspect(release) ($tkinspect(release_date))" \
	    -font $slot(font)
	ttk::label $self.com -text "\n Bugs, suggestions and patches to:\n\
                      http://sourceforge.net/projects/tkcon/ \n" \
	    -font $slot(obliqueFont)
	ttk::frame $self.mug
	ttk::label $self.mug.l -justify left \
            -text "Originally by Sam Shen\n\Contributions\
            from:\nPaul Healy\nJohn LoVerso\n\T. Schotanus\
            \nPat Thoyts\nAlexander Caldwell\n"

	global about_priv
	if ![info exists about_priv(mug_image)] {
	    set about_priv(mug_image) \
		[image create photo -file $tkinspect_library/sls.ppm]
	}
	ttk::label $self.mug.bm -image $about_priv(mug_image)
	pack $self.mug.l -side left -fill both -expand yes
	pack $self.mug.bm -fill none
	ttk::button $self.ok -text "Ok" -command "destroy $self"
	pack $self.title $self.ver $self.com $self.mug \
	    -in $self.border -side top -fill x
	pack $self.ok -in $self.border -side bottom -pady 5
	bind $self <Return> "destroy $self"
    }
    method reconfig {} {
    }
    method run {} {
	wm deiconify $self
	focus $self
	center_window $self
	tkwait visibility $self
	grab set $self
	tkwait window $self
    }
}
