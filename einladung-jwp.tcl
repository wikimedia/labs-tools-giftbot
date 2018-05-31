#!/data/project/shared/tcl/bin/tclsh8.7

# Bulk message delivery

# Copyright 2012 Giftpflanze

# einladung.tcl is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl

set template Wikipedia:Jungwikipedianer/Newsletter
set listpage Wikipedia:Jungwikipedianer/Newsletterliste
set section 1

set token [login [set wiki $dewiki]]
set text [content [post $wiki {*}$get / titles $listpage / rvsection $section]]
set pages [dict values [regexp -all -inline -line {(?:\[\[)(Wikipedia.*?|Benutzer.*?)(?:\||\]\])} $text]]
set date [string trim [clock format [clock seconds] -format "%e. %B %Y" -locale de -timezone Europe/Berlin]]

if {[clock add [clock scan [revision [post $wiki {*}$query / prop revisions / rvprop timestamp / titles $template] timestamp] -format %Y-%m-%dT%H:%M:%SZ] 1 week] > [clock seconds]} {
	foreach page $pages {
		puts [edit $page "Newsletter der \[\[WP:Jungwikipedianer|Jungwikipedianer\]\] ($date)" {} / appendtext "\n{{subst:$template}}" / redirect true]
	}
}
