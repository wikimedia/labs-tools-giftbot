#!/data/project/shared/tcl/bin/tclsh8.7

# adtbot

# Update of possible candidates for the Article of the Day (AdT)

# Copyright 2010, 2011, 2013, 2017 Giftpflanze

# adtbot is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl

set ret1 [post $dewiki {*}$get / titles {Benutzer:Hæggis/Kandidaten für den Artikel des Tages} / rvexpandtemplates true]
set ret2 [post $dewiki {*}$get / titles {Vorlage:Navigationsleiste Chronologien der Artikel des Tages}]

# chronology
foreach {-> chrono -} [regexp -all -inline {\[\[(Wikipedia:Hauptseite/Artikel des Tages/(Chronologie [0-9]{4}))\|.*?\]\]} [content $ret2]] {
	set ret3 [post $dewiki {*}$format / action expandtemplates / prop wikitext / text "{{$chrono}}"]
	lappend list {*}[dict values [regexp -all -inline {\[\[(?!Benutzer|:)(.*?)(?=\|.*?\]\]|\]\])} [get $ret3 expandtemplates wikitext]]]
}

# HAV
set ret6 [post $dewiki {*}$get / titles {Wikipedia Diskussion:Hauptseite/Artikel des Tages/Verwaltung/Lesenswerte Artikel} / rvsection 1]
lappend list {*}[dict values [regexp -all -inline {\[\[([^|]*?)\]\]} [content $ret6]]]

# discussed lemmas
set ret5 [post $dewiki {*}$format / action expandtemplates / prop wikitext / text {{{Wikipedia Diskussion:Hauptseite/Artikel des Tages/Index}}}]
foreach {-> title} [regexp -all -inline {\[\[..(/.*?)\|} [get $ret5 expandtemplates wikitext]] {
	set reti[incr i] [post $dewiki {*}$get / titles "Wikipedia Diskussion:Hauptseite/Artikel des Tages$title" / rvsection 1]
	lappend dict reti$i $title
}

foreach {return srctitle} $dict {
	foreach {section heading date title} [regexp -all -inline {\n== ([^\n]*?((?:\d{2}\.){2}\d{4}): \[\[([^\n]*?)\]\]) *==\n.*(?=\n=)} [content [set $return]]] {
		dict lappend rellist [string toupper $title 0 0]\
		 "\[\[Wikipedia Diskussion:Hauptseite/Artikel des Tages$srctitle#[string map {\[\[ {} \]\] {} <small> {} </small> {}} $heading]|<span style=\"color:#757575;\">$date</span>\]\]"
	}
}

# processing
set text [regsub -all {<imagemap>.*?</imagemap>} [content $ret1] {}]
set text [regsub -all {\[\[Datei:Loudspeaker\.svg\|12px\|verweis=Datei:Loudspeaker\.svg\|Gesprochener Inhalt\]\](&nbsp;| )(·|&middot;)*} $text {}]

# remove lemmas
foreach {section header} [regexp -all -inline {=== (.*?) ===.*?(?====|$)} $text] {
	set section2 $section
	foreach {subsection subheader} [regexp -all -inline {'''(.*?)'''.*?(?='''|$)} $section] {
		foreach {link ziel} [regexp -all -inline {\[\[(?!Datei|Bild|http)(.*?)(?:\|.*?)*\]\]} $subsection] {
			if {[string trim $ziel] in $list} {
				set section2 [string map [list $link {}] $section2]
			}
		}
	}
	# discussed lemmas
	foreach {title dates} $rellist {
		regsub -all "\\\[\\\[[string map {( \\( ) \\)} $title](?:\\|\[^\]\])*?\\\]\\\]" $section2\
		 "<small><span style=\"color:#757575;\">&\\&nbsp;([join [string map {& \\&} $dates] {,\&nbsp;}])</span></small>" section2
	}
	set text [string map [list $section $section2] $text]
}

#if $tcl_interactive return

# wikitext cleanup
set text [string map {&middot; · '''' {}} $text]; # encode dots and delete double quotes
set text [regsub -all -line {^[ ]\n} $text {}]; # blank lines
set text [regsub -all -line {^(&nbsp;·){1,2}[ ]{0,2}\n} $text {}]; # italics and dots
set text [regsub -all {&nbsp;·[ ]{0,2}\n} $text {}]; # back dots
set text [regsub -all {((?:\]\]|small>)(?:''){0,1}) *((?:''){0,1}(?:\[\[|<small))} $text {\1\&nbsp;· \2}]; # whitespace
set text [regsub -all -line {^'''.*?\:'''[ ]{0,2}\n$} $text {}]; # empty subsections
set text [regsub -all {(\n\n)\n*} $text {\1}]; # whitespace
set text [regsub -all {(\]\]|>)(\n''')} $text \\1\n\\2]; # blank subtopic lines
set text [regsub -all {\|(\n===)} $text |\n\\1]; # blank topic lines

set token [login [set wiki $dewiki]]
puts [edit {Wikipedia:Hauptseite/Artikel des Tages/Fundus} {Bot: Aktualisierung} $text / minor]
