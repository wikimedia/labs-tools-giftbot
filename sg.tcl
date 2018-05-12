#!/data/project/shared/tcl/bin/tclsh8.7

# sg.tcl

# Archive Did You Know on dewiki

# Copyright 2011, 2012 Giftpflanze

# sg?.tcl is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl

set insert {}
set clockopt {-locale de -timezone Europe/Berlin}

if ![llength $argv] {
	set argv {-2 days}
}

set seconds [clock scan $argv -timezone Europe/Berlin]

set ret1 [post $dewiki {*}$get / titles "Wikipedia:Hauptseite/Schon gewusst/[clock format [clock add $seconds 1 day 1 hour] {*}$clockopt -format %A]" / rvstart [clock format [clock add\
 $seconds 1 day] -format %Y%m%d%H%M%S]]
set ret3 [post $dewiki {*}$get / titles "Wikipedia:Hauptseite/Schon gewusst/[clock format $seconds {*}$clockopt -format %A]" / rvstart [clock format [clock add $seconds 1 day] -format\
 %Y%m%d%H%M%S]]

regexp {\n\* *([^\n]*)\n\* *([^\n]*)\n\* *([^\n]*)\n\* *([^\n]*)} [content $ret1] -> - - text1 text2
regexp {<div style="[^\n]*?">[ \n]*\[\[((?:[Bb]ild|[Dd]atei|[Ff]ile):[^\n]*)\]\][ \n]*</div>} [content $ret3] -> bild

if {![exists text1] || ![exists text2]} {
	puts {\n\* *([^\n]*)\n\* *([^\n]*)\n\* *([^\n]*)\n\* *([^\n]*)}
	puts ret1:[content $ret1]
	exit
}

if ![exists bild] {
	puts {<div style="[^\n]*?">[ \n]*\[\[((?:Bild|Datei|File):[^\n]*)\]\][ \n]*</div>}
	puts ret3:[content $ret3]
	exit
}

set insert "{{Hauptseite Schon-gewusst-Archivbox
|Datum=[set date [clock format $seconds -locale de -timezone Europe/Berlin -format {%e. %B %Y}]]
|Text=$text1
|Bild=\[\[$bild|right\]\]
}}

{{Hauptseite Schon-gewusst-Archivbox
|Datum=$date
|Text=$text2
|Bild=
}}"

#puts $insert; return; ##

set page "Wikipedia:Hauptseite/Schon gewusst/Archiv/[set date2 [clock format $seconds {*}$clockopt -format %Y/%m]]"

set ret2 [post $dewiki {*}$get / titles $page]
if [dict exists [page $ret2] missing] {
	set text "{{Navigationsleiste Hauptseite Schon-gewusst-Archiv|[clock format $seconds {*}$clockopt -format %Y]}}

\[\[Kategorie:Wikipedia:Hauptseite/Schon gewusst|Archiv/$date2\]\]"
} else {
	set text [content $ret2]
}

set text [string replace $text [set index [string first \}\} $text]]+3 $index+3 \n$insert\n\n]

set token [login [set wiki $dewiki]]
puts [edit $page "Bot: Ergänze Archiv für $date" $text]
#puts $text
