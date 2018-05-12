#!/data/project/shared/tcl/bin/tclsh8.7

# ibchem

# Find parameters without references in Template:Infobox Chemikalie

# Copyright 2011, 2012, 2014 Giftpflanze

# ibchem is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl

set wiki $dewiki

set parameters {
	Chemikalie {
		Beschreibung
		Dichte
		Schmelzpunkt
		Siedepunkt
		Sublimationspunkt
		Dampfdruck
		pKs
		Löslichkeit
		Dipolmoment
		Leitfähigkeit
		Brechungsindex
		{Quelle GHS-Kz}
		{Quelle P}
		{Quelle GefStKz}
		MAK
		LD50
		GWP
		Standardbildungsenthalpie
	}
	Polymer {
		Beschreibung
		Dichte
		Schmelzpunkt
		Glastemperatur
		Druckfestigkeit
		Härte
		Schlagzähigkeit
		Kristallinität
		Elastizitätsmodul
		Poissonzahl
		Wasseraufnahme
		Löslichkeit
		{Elektrische Leitfähigkeit}
		Zugfestigkeit
		Bruchdehnung
		{Chemische Beständigkeit}
		Viskositätszahl
		Wärmeformbeständigkeit
		Wärmeleitfähigkeit
		{Thermischer Ausdehnungskoeffizient}
		{Quelle GHS-Kz}
		{Quelle P}
		{Quelle GefStKz}
		LD50
	}
}

foreach type [dict keys $parameters] {
	set output2 "{{{Kasten|Auf dieser Seite werden Artikel gelistet, bei denen in der ''Infobox $type'' bei einem oder mehreren der Parameter [join [lrange [dict get $parameters $type] 0\
	 end-1] {, }] oder [lindex [dict get $parameters $type] end] eine Quellenangabe fehlt. Diese Seite wird jeweils zum Monatsersten aktualisiert.}}\n{{TOCright}}}"
	cont {ret1 {
		foreach item [embeddedin $ret1] {
			set ret2 [post $dewiki {*}$get / titles [dict get $item title]]
			set output {}
			foreach parameter [dict get $parameters $type] {
				set text {}
				regexp "(?w)^ *\\| *$parameter *= *(.*?)\n^( *\\||\}\}).*" [content $ret2] -> text
				foreach line [regexp -all -inline {(?n)^.*$} $text] {
					regsub {<!--.*?-->} $line {} line
					set line [string trim $line]
					if {[llength [split [string trim $line \n]]] && ![regexp {:$} $line] && !([regexp </*ref $line] || ($parameter in {{Quelle GefStKz} {Quelle GHS-Kz}} &&
					 ([regexp {\{\{(RL|CLP)\|} $line] || $line eq {NV} || $line eq {nv})) || ($parameter eq {} && ($line eq {NV} || $line eq {nv})))} {
						lappend output "$parameter = $line"
					}
				}
			}
			if [llength $output] {
				lappend output2 "== \[\[[dict get $item title]\]\] =="
				lappend output2 "<pre>\n[join $output \n]\n</pre>"
			}
		}
	}} {*}$embeddedin / eititle "Vorlage:Infobox $type" / einamespace 0
	set token [login [set wiki $dewiki]]
	puts [edit Benutzer:GiftBot/[dict get {Chemikalie Chemikalien Polymer Polymer} $type]liste {Bot: Aktualisierung} [join $output2 \n]]
}
