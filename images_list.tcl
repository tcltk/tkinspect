#
# $Id$
#
# Contributed by Gero Kohnert (gero@marvin.franken.de) 1995
#

widget images_list {
    object_include tkinspect_list
    param title "Images"
    method create {} {
	tkinspect_list:create $self
	$slot(menu) add separator
	$slot(menu) add command -label "Show Image" -underline 5 \
	    -command "$self show_image"
    }
    method get_item_name {} { return image }
    method update {target} {
	$self clear
	foreach image [lsort [send $target image names]] {
	    $self append $image
	}
    }
    method retrieve {target image} {
	set result "# image configuration for [list $image]\n"
	append result "# ([send $target image width $image]x[send $target image height $image] [send $target image type $image] image)\n"
	append result "$image config"
	foreach spec [send $target [list $image config]] {
	    if {[llength $spec] == 2} continue
	    append result " \\\n\t[lindex $spec 0] [list [lindex $spec 4]]"
	}
	append result "\n"
	return $result
    }
    method send_filter {value} {
	return $value
    }
    method show_image {} {
	set target [$slot(main) target]
	if ![string length $slot(current_item)] {
	    tkinspect_failure \
	     "No image has been selected.  Please select one first."
	}
	if ![send $target info exists __tkinspect_image_counter__] {
	    send $target set __tkinspect_image_counter__ 0
	}
	while {[send $target winfo exists .tkinspect_image\$__tkinspect_image_counter__]} {
	    send $target incr __tkinspect_image_counter__
	}
	set w .tkinspect_image[send $target set __tkinspect_image_counter__]
	send $target [subst {
	    toplevel $w
	    button $w.close -text "Close $slot(current_item)" \
		-command "destroy $w"
	    label $w.img -image $slot(current_item)
	    pack $w.close $w.img -side top
	    wm title $w "tkinspect $slot(current_item)"
	}]
    }
}
