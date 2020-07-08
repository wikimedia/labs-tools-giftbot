#!/data/project/shared/tcl/bin/tclsh8.7

# rü.tcl

# Clean Vorlage:Rückblick

# Copyright 2011, 2012 Giftpflanze

# rü.tcl is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl

set text [content [post $dewiki {*}$get / titles Vorlage:Rückblick]]
foreach {-> row date} [regexp -all -inline {(?n)\n(\|-.*?\n\|.*\n\|.*\n\|.*<!--.*?(\d{1,2}\. [^ ]*? \d{4}).*?--> *(?:\n|</onlyinclude>))} $text] {
	if {[clock add [clock scan $date -format {%d. %B %Y} -locale de -timezone Europe/Berlin] 1 week 1 day] < [clock seconds]} {
		set text [string map [list $row {}] $text]
	}
}
set token [login [set wiki $dewiki]]
puts [edit Vorlage:Rückblick {Bot: entferne abgelaufene Einträge} $text]
