#!/data/project/shared/tcl/bin/tclsh8.7

# daysection.tcl

# Day sections for de:WP:KALP and :SH

# Copyright 2011, 2012, 2014 Giftpflanze

# daysection.tcl is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl

set token [login [set wiki $dewiki]]

proc heading {{offset 0}} {
	return [string trim [clock format [clock add [clock seconds] $offset days -timezone Europe/Berlin] -timezone Europe/Berlin -locale de -format {%e. %B}]]
}

proc heading2 {} {
	return [string trim [clock format [clock seconds] -timezone Europe/Berlin -locale de -format {%e. %B %Y}]]
}

#does not really detect editconflict, don't know why
foreach {title id} {{Wikipedia:Kandidaturen von Artikeln, Listen und Portalen} 1 {Wikipedia:Kandidaten für lesenswerte Artikel} 2} {
	if [catch {
		switch $id {
			1 {
				set subst "== [heading] ==\n<small>Diese Kandidaturen laufen mindestens bis zum [heading 10]/[heading 20].</small>"
				set re {==[^\n]*?==\n<small>Diese Kandidaturen laufen mindestens bis zum [^\n]*?/[^\n]*?\.</small>\Z}
			}
			2 {
				set subst "== [heading] ==\n<small>Diese Kandidaturen laufen mindestens bis zum [heading 10].</small>"
				set re {==[^\n]*?==\n<small>Diese Kandidaturen laufen mindestens bis zum [^\n]*?\.</small>\Z}
			}
		}
		do {
			if [regexp $re [set text [content [set ret1 [post $wiki {*}$get / titles $title / rvprop content|timestamp]]]]] {
				puts [set ret2 [edit $title {Bot: ersetze Tagesabschnitt} [regsub $re $text $subst] / nocreate true / basetimestamp [revision $ret1 timestamp]\
				 / starttimestamp [revision $ret1 timestamp]]]
			} else {
				puts [set ret2 [edit $title {Bot: neuer Tagesabschnitt} {} / appendtext "\n\n$subst" / nocreate true]]
			}
		} while {[exists ret2] && [dict exists $ret2 error code] && [dict get $ret2 error code] eq {editconflict}}
	}] {
		puts $errorCode
		puts $errorInfo
	}
}

foreach title {{Wikipedia:Fragen zur Wikipedia} Wikipedia:Auskunft Wikipedia:Löschprüfung} {
	do {
		if [regexp [set re {=[^\n]*?=\Z}] [set text [content [set ret1 [post $wiki {*}$get / titles $title / rvprop content|timestamp]]]]] {
			puts [set ret2 [edit $title {Bot: ersetze Tagesabschnitt} [regsub $re $text "= [heading] ="] / nocreate true / basetimestamp [revision $ret1 timestamp]]]
		} else {
			puts [set ret2 [edit $title {Bot: neuer Tagesabschnitt} {} / appendtext "\n\n= [heading] =" / nocreate true]]
		}
	} while {[exists ret2] && [dict exists $ret2 error code] && [dict get $ret2 error code] eq {editconflict}}
}

foreach {title offset} {Wikipedia:LKH 0 Wikipedia:Löschkandidaten/heute 0 Wikipedia:LKG -1 Wikipedia:Löschkandidaten/gestern -1 Wikipedia:LK7 -7 Wikipedia:QSH 0 Wikipedia:Qualitätssicherung/heute 0} {
	puts [edit $title {Bot: aktualisiere Weiterleitung} [
		regsub {\d{1,2}\. .* \d{4}} [content [post $dewiki {*}$get / titles $title]] [
			string trim [clock format [clock add [clock seconds] $offset days] -format {%e. %B %Y} -locale de -timezone Europe/Berlin]
		]
	] / nocreate true]
}
