#!/data/project/shared/tcl/bin/tclsh8.7

# inaktivebots.tcl

# Update status on WP:Bots/Liste der Bots and categorization of bot user pages

# Copyright 2016 Giftpflanze

# inaktivebots.tcl is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl
source cat.tcl

set token [login [set wiki $dewiki]]

foreach user [concat [cat {Kategorie:Benutzer:Bot mit Flag} 2] [cat {Kategorie:Benutzer:Bot ohne Flag} 2]] {
	if {[set ts [lastcontrib [post $wiki {*}$lastcontrib / ucuser $user]]] ne {} && [clock add [set ts [scan-ts $ts]] 6 months] < [clock seconds]} {
		lappend o |[regsub Benutzer: $user {}]=[clock format $ts -format %Y%m%d]
	}
}

set text [content [post $wiki {*}$get / titles [set title {Wikipedia:Bots/Liste der Bots/inaktiv}]]]
regexp -indices {\{\{\{1\|\}\}\}\n(.*)\n\|#default=Nein} $text -> i
set text [string replace $text {*}$i [join $o \n]]

puts [edit $title {Bot: Update} $text]
