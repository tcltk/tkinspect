#
# $Id$
#
# A entry in a frame with a label.
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

widget simpleentry {
    param label ""
    param width 10
    param textvariable ""
    method create {} {
	set w $self
	label $w.l
	pack $w.l -in $w -side left
	entry $w.e -relief sunken -bd 2
	pack $w.e -in $w -side left -fill x -expand 1
    }
    method reconfig {} {
	set w $self
	$w.l config -text $slot(label)
	$w.e config -width $slot(width) -textvariable $slot(textvariable)
    }
    method entry args {
	uplevel [concat $self.e $args]
    }
    method bind {event args} {
	uplevel [concat [list bind $self.e $event] $args]
    }
}
