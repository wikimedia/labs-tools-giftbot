#!/data/project/shared/tcl/bin/tclsh8.7

# Find mineral images on Commons that are missing on dewiki

# Copyright 2019 Giftpflanze

# mineralbilder.tcl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.

package require struct::set

source api.tcl
source dewiki.tcl
source commons.tcl
source cat.tcl
source library.tcl

set token [login [set wiki $dewiki]]
set db_dewiki [get-db dewiki]
set db_commons [get-db commonswiki]

set fpsrcpage {Commons:Featured pictures/Objects/Rocks and minerals}
set qisrcpage {Commons:Quality images/Subject/Objects/Geological objects/Rocks, Minerals, Elements}
set visrcpage {Commons:Valued images by topic/Objects/Geological objects/Rocks, minerals and elements}

set fpdestpage {Portal:Minerale/Exzellente Bilder}
set qidestpage Portal:Minerale/Qualitätsbilder
set videstpage {Portal:Minerale/Wertvolle Bilder}

set destcat Mineral
set destcat2 Mineralgruppe

set destpage {Portal Diskussion:Minerale/Galerie}

proc extract-galleries {wiki title} {
	global get
	foreach gallery [dict values [regexp -all -inline {<gallery.*?> *\n(.*)\n</gallery>} [string map {\n\n \n} [content [post $wiki {*}$get / titles $title / redirects]]]]] {
		lappend return {*}[lmap title [dict values [regexp -all -inline {(?n)^(.*?) *(?=\||$)} $gallery]] {string map {Datei: {} Bild: {} File: {} Image: {}} $title}]
	}
	return $return
}

foreach t {src dest} w {commons dewiki} {
	foreach v {fp qi vi} {
		set ${v}${t}list [extract-galleries [set $w] [set ${v}${t}page]]
	}
}

set destlist [struct::set union $fpdestlist $qidestlist $videstlist]

set destcatlist [struct::set union [cat-db $db_dewiki $destcat 0] [cat-db $db_dewiki $destcat2 0]]

lappend output "== Neue Bilder =="

foreach v {fp qi vi} h {{Exzellente Bilder} Qualitätsbilder {Wertvolle Bilder}} {
	lappend output "=== $h ===" <gallery>
	foreach image [lsort [set ${v}srclist]] {
		if {[string length $image] && $image ni $destlist} {
			set titles {}
			foreach title [lsort [dict values [regexp -all -inline {(?n)\[\[:de:(.*?)(?=\||$)} [content [post $commons {*}$get / titles File:$image / redirects]]]]] {
				if {$title in $destcatlist} {
					lappend titles $title
				}
			}
			if [llength $titles] {
				lappend output $image|[join [lmap title $titles {format {[[%s]]} $title}] {, }]
			}
		}
	}
	lappend output </gallery>
}

puts [edit $destpage {Bot: Bilder aus Commons} [join $output \n]]
