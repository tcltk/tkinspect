#
# $Id$
#
# Contributed by Gero Kohnert (gero@marvin.franken.de) 1995
#

widget images_list {
    object_include tkinspect_list
    param title "Images"
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
}
