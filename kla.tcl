#!/data/project/shared/tcl/bin/tclsh8.7

# kla.tcl

# Abgleich der LA/EA/IL-Anzahlen in Kategorie und Liste

# Copyright 2013, 2017 Giftpflanze

# kla.tcl is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

package require struct::set

source api.tcl
source dewiki.tcl
source cat.tcl
source library.tcl

proc resolveredirects {list} {
	global sql
	lmap lemma $list {
		if [llength [set dest [string map {_ { }} [mysqlsel $sql "select rd_title from redirect, page where page_namespace = 0 and page_title = '[mysqlescape [string map {{ } _}\
		 $lemma]]' and rd_from = page_id" -list]]]] {
			set dest
		} else {
			set lemma [string toupper [string trim [string map {_ { }} $lemma]] 0 0]
		}
	}
}

set token [login [set wiki $dewiki]]
set sql [get-db dewiki]

set lacat [cat Kategorie:Wikipedia:Lesenswert 0]
set latext [content [post $dewiki {*}$get / titles {Wikipedia:Lesenswerte Artikel/nach Datum} / rvexpandtemplates true]]
set lalist [lmap {-> lemma} [regexp -all -inline {(?w)^# *?'*\[\[(.*)(?:\]\]|\|)} $latext] {set lemma}]
set latext2 [content [post $dewiki {*}$get / titles {Wikipedia:Lesenswerte Artikel} / rvexpandtemplates true]]
regsub -all {&nbsp;} $latext2 { } latext2
set lalist2 [lmap {-> lemma} [regexp -all -inline {(?n)^(?:\[\[Datei:Loudspeaker\.svg\|12px\|verweis=Datei:Loudspeaker\.svg\|Gesprochener Inhalt\]\]\
 )??'*\[\[(?!#|Bild:|Datei:|File:|Kategorie:|ky:)(.*)(?:\]\]|\|)} $latext2] {set lemma}]
set latext3 [content [post $dewiki {*}$get / titles {Wikipedia:Hauptseite/Artikel des Tages/Verwaltung/Lesenswerte Artikel}]]
set lalist3 [lmap {-> lemma} [regexp -all -inline {(?n)^# *?(?:{{Gesprochen}} )?'*\[\[(?!Kategorie:)(.*)(?:\]\]|\|)} $latext3] {set lemma}]

set eacat [cat Kategorie:Wikipedia:Exzellent 0]
set eatext [content [post $dewiki {*}$get / titles {Wikipedia:Exzellente Artikel/nach Datum} / rvexpandtemplates true]]
set ealist [lmap {-> lemma} [regexp -all -inline {(?w)^# *?(?:<li value=".*">)* *'*\[\[(.*)(?:\]\]|\|)} $eatext] {set lemma}]
set eatext2 [content [post $dewiki {*}$get / titles {Wikipedia:Exzellente Artikel} / rvexpandtemplates true]]
regsub -all {&nbsp;} $eatext2 { } eatext2
set ealist2 [lmap {-> lemma} [regexp -all -inline {(?n)^(?:\[\[Datei:Loudspeaker\.svg\|12px\|verweis=Datei:Loudspeaker\.svg\|Gesprochener Inhalt\]\]\
 )??'*\[\[(?!#|Bild:|Datei:|File:|Kategorie:|ml:)(.*)(?:\]\]|\|)} $eatext2] {set lemma}]
set eatext3 [content [post $dewiki {*}$get / titles {Wikipedia:Hauptseite/Artikel des Tages/Verwaltung}]]
regsub -all {&nbsp;} $eatext3 { } eatext3
set ealist3 [lmap {-> lemma} [regexp -all -inline {(?n)^# *?(?:{{Gesprochen}} )?'*\[\[(.*)(?:\]\]|\|)} $eatext3] {set lemma}]

set ilcat [cat {Kategorie:Wikipedia:Informative Liste} 0]
set iltext [content [post $dewiki {*}$get / titles {Wikipedia:Informative Listen und Portale/Nach Datum} / rvsection 2]]
set illist [lmap {-> lemma} [regexp -all -inline {(?w)^# *?'*\[\[(.*)(?:\]\]|\|)} $iltext] {set lemma}]
set iltext2 [content [post $dewiki {*}$get / titles {Wikipedia:Informative Listen und Portale} / rvexpandtemplates true]]
set illist2 [lmap {-> lemma} [regexp -all -inline {(?n)'*?\[\[(?!#|//|Bild:|Datei:|File:|Hilfe:|Kategorie:|Portal:|Wikipedia:|:Kategorie:)(.*)(?:\]\]|\|)} $iltext2] {set lemma}]

#return; #

puts [edit {Benutzer:GiftBot/KLA} {Unstimmigkeiten} "{| class=\"wikitable\"\n|-\n! !! nur Kategorie !! nur Liste (nach Datum)\n|-\n| Lesenswerte Artikel || [join [lmap list [lrange [struct::set intersect3\
 $lacat [resolveredirects $lalist]] 1 2] {join [lmap lemma $list {set lemma \[\[$lemma\]\]}] {, }}] ||]\n|-\n| Exzellente Artikel || [join [lmap list [lrange [struct::set intersect3 $eacat\
 [resolveredirects $ealist]] 1 2] {join [lmap lemma $list {set lemma \[\[$lemma\]\]}] {, }}] ||]\n|-\n| Informative Listen || [join [lmap list [lrange [struct::set intersect3 $ilcat\
 [resolveredirects $illist]] 1 2] {join [lmap lemma $list {set lemma \[\[$lemma\]\]}] {, }}] ||]\n|}\n{| class=\"wikitable\"\n|-\n! !! nur Kategorie !! nur Liste\n|-\n|\
 Lesenswerte Artikel || [join [lmap list [lrange [struct::set intersect3 $lacat [resolveredirects $lalist2]] 1 2] {join [lmap lemma $list {set lemma \[\[$lemma\]\]}] {, }}] ||]\n|-\n|\
 Exzellente Artikel || [join [lmap list [lrange [struct::set intersect3 $eacat [resolveredirects $ealist2]] 1 2] {join [lmap lemma $list {set lemma \[\[$lemma\]\]}] {, }}] ||]\n|-\n|\
 Informative Listen || [join [lmap list [lrange [struct::set intersect3 $ilcat [resolveredirects $illist2]] 1 2] {join [lmap lemma $list {set lemma \[\[$lemma\]\]}] {, }}] ||]\n|}\n{|\
 class=\"wikitable\"\n|-\n! !! nur Kategorie !! nur Liste (Verwaltung)\n|-\n| Lesenswerte Artikel || [join [lmap list [lrange [struct::set intersect3 $lacat [resolveredirects $lalist3]] 1 2]\
 {join [lmap lemma $list {set lemma \[\[$lemma\]\]}] {, }}] ||]\n|-\n| Exzellente Artikel || [join [lmap list [lrange [struct::set intersect3 $eacat [resolveredirects $ealist3]] 1 2] {join\
 [lmap lemma $list {set lemma \[\[$lemma\]\]}] {, }}] ||]\n|}"]
