#!/data/project/shared/tcl/bin/tclsh8.7

# sikubot

# remove locally non-existent files from page

# Copyright 2011 Giftpflanze

# sikubot is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl

set target {Benutzer:Siku-Sammler/gefundene Bilder}

set ret1 [post $dewiki {*}$get / titles $target]
foreach page [regexp -all -inline {(?ni)^(?:Bild|Datei|Image|Source):.*?(?=\||$)} [set text [content $ret1]]] {
	if [dict exists [page [post $dewiki {*}$format / action query / prop info / titles $page]] missing] {
		regsub (?q)$page\n $text {} text
	}
}

set token [login [set wiki $dewiki]]
puts [edit $target {Bot: entferne lokal nicht vorhandene Bilder} $text]
