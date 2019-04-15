#!/data/project/shared/tcl/bin/tclsh8.7

# Ausrufer

# Delivery of community related news in the German Wikipedia.

# Copyright 2010, 2011, 2012, 2013, 2014, 2018 Giftpflanze

# Ausrufer is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

package require cmdline

source api.tcl
source dewiki.tcl
source config.tcl

dict for {key value} [cmdline::getKnownOptions argv {{mode.arg} {ts.arg}}] {
	if {$value ne {}} {
		set $key $value
	}
}
if [exists ts] {
	lappend get / rvstart ${ts}000000
}


# Input:

set olddict [read [set file [open state]]][close $file]

#puts Vorlage:Beteiligen
set list1 {}
set text1 [content [post $dewiki {*}$get / titles Vorlage:Beteiligen]]
regsub -all {(?n)^<!--\n} $text1 {} text1
regsub -all {(?n)^-->\n} $text1 {} text1
regsub -all {(?n)^\|-->$} $text1 {|} text1
regsub -all {(?n)^\|- -->$} $text1 {|-} text1
foreach row [regexp -all -inline {(?w)\|-.*?(?=^\|-|\|\}|-->)} $text1] {
	set list1 {}
	if ![regexp {\|- *\n\| *'''[^[]*?\[*(.*?)\]*:[^]]*?''' *\n\| *(.*)(?=\n)} $row -> header content] continue
	regexp {.*(?=^|\|)\|*(.*)} $header -> caption
	unset header
	foreach item [regexp -all -inline {\[\[.*?\]\]} $content] {
		unset -nocomplain title
		regexp {\[\[(.*?)\|(.*)\]\]} $item -> title
		if ![exists title] {regexp {\[\[(.*?)\]\]} $item -> title}
		if [catch {set pageid [page [post $dewiki {*}$query / prop info / titles $title] pageid]}] {
			set pageid [string trim $title]
		}
		lappend list1 $pageid [string trim $item]
	}
	dict set newdict $caption $list1
}

#puts Wikipedia:Meinungsbilder
set list2 {}
foreach section {3 4} {
	set text2 [content [post $dewiki {*}$get / titles Wikipedia:Meinungsbilder / rvsection $section / rvexpandtemplates true]]
	foreach row [regexp -all -inline {\|- \n.*?(?=\|-|\|\})} $text2] {
		if ![regexp {\[\[(.*?)\|.*?\]\]} $row match link] continue
		set pageid [page [post $dewiki {*}$query / prop info / titles $link] pageid]
		lappend list2 $pageid $match
	}
}
dict set newdict {Meinungsbilder in Vorbereitung} $list2

#puts Wikipedia:Umfragen
set list3 {}
set text3 [content [post $dewiki {*}$get / titles Wikipedia:Umfragen / rvsection 4]]
foreach line [regexp -all -inline {\[\[.*?\]\]} $text3] {
	unset -nocomplain pageid
	if ![regexp {\[\[(Wikipedia:Umfragen/.*?)\|.*?\]\]} $line match link] {
		if ![regexp {\[\[(Wikipedia:Umfragen/.*?)\]\]} $line match link] {
			continue
		}
	}
	catch {set pageid [page [post $dewiki {*}$query / prop info / titles $link] pageid]}
	if [exists pageid] {
		lappend list3 $pageid $match
	}
}
dict set newdict {Umfragen in Vorbereitung} $list3

#puts Wikipedia:Benutzersperrung
set list4 {}
if 0 {###
set text4 [content [post $dewiki {*}$get / titles Wikipedia:Benutzersperrung / rvsection 2]]
foreach line [regexp -all -inline {\[\[.*?\]\]} $text4] {
	if ![regexp {\[\[(Wikipedia:Benutzersperrung/.*?)\]\]} $line match link] {
		if ![regexp {\[\[(.*?)\|.*?\]\]} $line match link] {
			if ![regexp {\[\[(.*?)\]\]} $line match link] {
				continue
			}
		}
	}
	set pageid [page [post $dewiki {*}$query / prop info / titles $link] pageid]
	lappend list4 $pageid $match
}
}
dict set newdict {Benutzersperrungen in Vorbereitung} $list4

#puts Wikipedia:Kurier
set list5 {}
set text5 [content [post $dewiki {*}$get / titles Wikipedia:Kurier]]
set parts [regexp -all -inline {\n= .*? =\n.*?(?=\n= .*? =\n|$)} $text5]
foreach {regexp list part} [list {\n==([^=].*?)==[ \t]*\n} kllist [lindex $parts 0] {\n===(.*?)===[ \t]*\n} krlist [lindex $parts 1]] {
	foreach {match section} [regexp -all -inline $regexp $part] {
		set section [regsub -all {=(.*)=} $section {\1}]; #3rd level headings
		set section [regsub -all {{{[Aa]nker\|.*?}}} $section {}]; #anchor template
		set section [regsub -all {\[\[.*?\|(.*?)\]\]} $section {\1}]; #link substitution I
		set section [regsub -all {<(.*?)(?: .*?)*>(.*?)</\1>} $section {\2}]; #tag markup removal I
		set section [regsub -all {<.*?/>} $section {}]; #tag markup removal II
		set section [regsub -all {\[http://[^ ]*? ([^]]*?)\]} $section {\1}]; #weblink substitution
		set section [string map {\[\[\[\[ &#91;&#91; \]\]\]\] &#93;&#93; \[\[ {} \]\] {} \[ &#91; \] &#93;} $section]; #link substitution II
		set section [regsub -all {<!--.*-->} $section {}]; #comment removal
		set section [string trim $section]; #whitespace
		lappend $list $section \[\[WP:K#[string map {''' {} '' {} ' &#39;} $section]|$section\]\]; #single quote markup substitution
	}
}

#puts Wikipedia:Projektneuheiten
set text6 [content [post $dewiki {*}$get / titles Wikipedia:Projektneuheiten]]
if {[clock format [clock seconds] -format %d%m%Y] eq {10102011}} {
	regsub {\n==== .*?(?=\n=== )} $text6 {* [[WP:NEU#Version 1.18|MediaWiki 1.18]]} text6
}
foreach {-> date items} [regexp -all -inline {\n=== ([0-9]+?\. .*) === *\n(.*?)(?=\n+?===? )} $text6] {
	lappend neulist $date [regsub -all {(?p)==== *(.*?) *====} $items {;\1}]
}

#puts Vorlage:Rückblick
set rü [string map {\n\n\n\n \n} [get [post $dewiki {*}$format / action expandtemplates / prop wikitext / text "{|{{Rückblick}}|}"] expandtemplates wikitext]]
regsub {([^\n])\|\}} ${rü} "\\1\n|\}" rü


# Processing:

foreach key [dict keys $newdict] {
	foreach {title link} [dict get $newdict $key] {
		if {![dict exists $olddict $key] || $title ni [dict get $olddict $key]} {
			lappend list6 $link
		}
	}
	if [exists list6] {
		lappend newitems "$presep$key:$intersep[join $list6 $listsep]"
		unset list6
	}
}
foreach {char key} {l {Kurier – linke Spalte} r {Kurier – rechte Spalte}} {
	if ![exists k${char}list] {
		set k${char}newlist {}
		continue
	}
	foreach {title link} [set k${char}list] {
		if {$title ni [dict get $olddict $key]} {
			lappend k${char}sections $link
			lappend k${char}newlist $title $link
		} else {
			break
		}
	}
	if [exists k${char}sections] {
		set k${char}item "$presep$key:$intersep[join [set k${char}sections] $listsep]"
	} else {
		set k${char}newlist [list $title $link]
	}
	dict set newdict $key [set k${char}newlist]
}
foreach {date list7} $neulist {
	if {$date ne [dict get $olddict Projektneuheiten]} {
		lappend neunewlist $list7
	} else {
		break
	}
}
if [exists neunewlist] {
	set neuitem "${presep}Projektneuheiten:\n[string map {\n\n \n} [join [lreverse $neunewlist] \n]]"
}
dict set newdict Projektneuheiten [lindex $neulist 0]
if [regexp → ${rü}] {
	set rüitem "${presep}Rückblick:\n${rü}"
	set rüitem2 [regsub -all {(?n)\[\[(?:[Bb]enutzer(?:in)?|[Uu]ser):(.*?)\|\1\]\]} ${rüitem} {{{noping|\1}}}]
	set rüitem2 [regsub -all {(?n)\[\[(?:[Bb]enutzer(?:in)?|[Uu]ser):(.*?)\|(.*?)\]\]} ${rüitem2} {{{noping|\1|\2}}}]
}

if {$mode == 2} {
	if [exists newitems] {
		puts [join $newitems \n]
	}
	foreach prefix {kl kr neu rü} {
		if [exists ${prefix}item] {
			puts [set ${prefix}item]
		}
	}
}


# Output:

set token [login [set wiki $dewiki]]
set week "\[\[$page|Ausrufer\]\] – [string trimleft [clock format [clock seconds] -format %V -timezone Europe/Berlin] 0]. Woche"
if {([exists newitems] || [exists klitem] || [exists kritem] || [exists neuitem] || [exists rüitem]) && $mode == 1} {
	set text [content [post $dewiki {*}$get / titles $page / rvsection 1]]
	if ![exists newitems] {
		set newitems {}
	}
	foreach line [concat [regexp -all -inline {#.*?(?=\n)} $text] $hiddenpages] {
		#format: [[Benutzer:$user/Ausrufer|$user]]
		if ![regexp {([^[]*:([^]/|]*)[^]|]*)(?:\]\]|\|)} [string map {_ { }} $line] -> title user] {
			continue
		}
		set title [string map {{Benutzer Diskussion:} BD: {Benutzerin Diskussion:} BD:} [page [post $wiki {*}$redirect / titles $title] title]]
		set user [string map {Benutzer: {} Benutzerin: {} {Benutzer Diskussion:} {} {Benutzerin Diskussion:} {}} [page [post $wiki {*}$redirect / titles Benutzer:$user] title]]
		set ret2 [post $dewiki {*}$lastcontrib / ucuser $user]
		try {
			if {[clock add [set ts [scan-ts [lastcontrib $ret2]]] 6 months] < [clock seconds]} {
				puts [edit BD:$user "Austragung aus dem \[\[$page|Ausrufer\]\]" {Du wurdest automatisch aus der Verteilerliste des Ausrufers ausgetragen, da du seit einem\
				 halben Jahr nicht mehr in der Wikipedia editiert hast. – ~~~~} / section new]
				continue
			}
		} on error {} continue
		if {$line ni $hiddenpages} {
			lappend ppageoutput [list $user "# \[\[$title|$user\]\][join [list\
				[expr {[regexp {{{/Abschnitt\|(.*?)}}} $line -> section]?"{{/Abschnitt|$section}}":{}}]\
				[expr {[regexp {{{/K}}} $line]?{{{/K}}}:{}}]\
				[expr {[regexp {{{/NEU}}} $line]?{{{/NEU}}}:{}}]\
				[expr {[regexp {{{/RÜ}}} $line]?{{{/RÜ}}}:{}}]
			] {}]"]
		}

                if {![exists cont] && [clock format [clock seconds] -format %d%m%Y -timezone Europe/Berlin] eq {05102015}} {
                        if {$user eq {RonMeier}} {
                                set cont true
                        }
                        continue
                }

		set useritems {}
		if {[regexp {\{\{/RÜ\}\}} $line] && [exists rüitem2]} {
			lappend useritems ${rüitem2}
		}
		lappend useritems {*}$newitems
		if {[clock format [clock seconds] -format %d%m%Y] eq {25072011} && ![regexp {\{\{/RÜ\}\}} $line]} {
			lappend useritems "${presep}Ausrufer:${intersep}Neue Option <nowiki>{{/RÜ}}</nowiki> bzw. |RÜ= für \[\[Vorlage:Rückblick\]\]"
		}
		if [regexp {\{\{/K\}\}} $line] {
			foreach item {klitem kritem} {
				if [exists $item] {
					lappend useritems [set $item]
				}
			}
		}
		if {[regexp {\{\{/NEU\}\}} $line] && [exists neuitem]} {
			lappend useritems $neuitem
		}
		if ![string length $useritems] {
			continue
		}
		set usertext [string map "|\}<br> |\}" [join "$useritems {– ~~~~}" $itemsep]]
		if {$mode == 1} {
			if [regexp {(BD|Benutzer(in)?[_ ]Diskussion):.*} $title] { # user talk page
				if {[regexp {\{\{/Abschnitt\|(.*?)\}\}} $line -> section] && $section ne {neu}} {
					edit $title "Bot: \[\[$page|Ausrufer\]\]" "== $week ==\n\n$usertext" / section $section
				} else {
					edit $title $week $usertext / section new
				}
			} else { # user page
				set section {}
				regexp {\{\{/Abschnitt\|(.*?)\}\}} $line -> section
				if {$section eq {neu}} {
					edit $title $week $usertext / section new
				} else {
					if {[dict exists [set ret1 [
						edit $title "Bot: \[\[$page|Ausrufer\]\]" {} / appendtext \n\n$usertext {*}[expr {[llength $section]?"/ section $section":{}}]
					]] error code] && [dict get $ret1 error code] == {nosuchsection}} {
						edit $title {Bot: Ausrufer-Fehler} {} / appendtext "Es gibt keinen Abschnitt $section – ~~~~"
					}
				}
			}
		}
	}
	set pageoutput {{== Seitenliste ==} {}}
	foreach item [lsort -dictionary -index 0 $ppageoutput] {
		lappend pageoutput [lindex $item 1]
	}
	lappend pageoutput {} {<!-- BITTE IN ALPHABETISCHER REIHENFOLGE GEMÄSS BENUTZERNAMEN EINTRAGEN! -->}
	edit $page {Bot: automatische Sortierung und Formatierung, Inaktive ausgetragen} [join $pageoutput \n] / section 1
}

#puts Vorlage:
set templatetext {<noinclude>{{/Doku}}</noinclude>
}
if [exists rüitem] {
	append templatetext "<includeonly>\{\{#ifeq:\{\{\{RÜ\}\}\}||</includeonly>[string map [list | {{{!}}}] ${rüitem}]<includeonly>\}\}</includeonly>\n"
}
if [exists newitems] {
	append templatetext [string map {| {{{!}}}} [join $newitems $itemsep]]
}
foreach item {klitem kritem} {
	if [exists $item] {
		lappend ktext [set $item]
	}
}
if [exists ktext] {
	append templatetext "<includeonly>\{\{#ifeq:\{\{\{K\}\}\}||</includeonly>$itemsep[join $ktext $itemsep]<includeonly>\}\}</includeonly>"
}
if [exists neuitem] {
	append templatetext "<includeonly>\{\{#ifeq:\{\{\{NEU\}\}\}||</includeonly>$itemsep$neuitem<includeonly>\}\}</includeonly>"
}
append templatetext {<noinclude>[[Kategorie:Vorlage:Benutzer:|Ausrufer]]</noinclude>}
if {$mode == 1} {
	edit $page/Vorlage {Bot: aktualisiere Vorlage} $templatetext
}

if {$mode < 2} {
	puts -nonewline [set file [open state w]] $newdict
}
