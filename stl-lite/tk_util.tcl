#
# $Id$
#
# Misc procs for use with Tk
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

proc center_window {win} {
    wm withdraw $win
    update idletasks
    set w [winfo reqwidth $win]
    set h [winfo reqheight $win]
    set sh [winfo screenheight $win]
    set sw [winfo screenwidth $win]
    wm geometry $win +[expr {($sw-$w)/2}]+[expr {($sh-$h)/2}]
    wm deiconify $win
}

proc under_mouse {win} {
    set xy [winfo pointerxy $win]
    wm withdraw $win
    wm geometry $win +[expr [lindex $xy 0] - 10]+[expr [lindex $xy 1] - 10]
    wm deiconify $win
}
