#!/data/project/shared/tcl/bin/tclsh8.7

# sga.tcl

# Create talk page for new arbcom cases

# Copyright 2015 Giftpflanze

# sga.tcl is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl
source irc.tcl

set quiet true
set token [login [set wiki $dewiki]]

register-rc de.wikipedia {{channel - title action - - - -} {
	global dewiki
	if {$channel eq {de.wikipedia} && [string match Wikipedia:Schiedsgericht/Anfragen/* $title] && [regexp N $action]} {
		puts [edit [string map {Wikipedia {Wikipedia Diskussion}} $title] {Bot: Lege Diskussionsseite an} "{{Diskussionsseite|Zweck=Diese Diskussionsseite dient dazu, unklare Punkte an\
		 der ''Projektseite'' \[\[$title|[string map {Wikipedia:Schiedsgericht/Anfragen/ {}} $title]\]\] zu diskutieren, sachdienliche Hinweise zu liefern und auf eventuelle Fehler\
		 oder Probleme aufmerksam zu machen, die bei der Bearbeitung der Anfrage durch die Schiedsrichter auftreten.\n\n'''Allgemeine Betrachtungen zum Projektzustand,\
		 Ad-personam-Diskussionen und süffisante Spitzen gegen einzelne Beteiligte gehören nicht hierher.'''}}" / createonly]
	}
}}

vwait exit
