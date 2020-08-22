#!/data/project/shared/tcl/bin/tclsh8.7

# ckmpbot

# Check German Wikipedia Mentorship Program category relations

# Copyright 2011, 2012, 2015, 2018 Giftpflanze

# ckmpbot is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

package require cmdline
package require struct::set

source api.tcl
source dewiki.tcl

dict for {key value} [cmdline::getKnownOptions argv {{manual} {all} {forgotten}}] {
	set $key $value
}

set wpmp Wikipedia:Mentorenprogramm
set utmpl {Benutzer:%s/Vorlage Mentor}
set wmtmpl Mentorenprogramm/preload/Wunschmentor/
set optin Wikipedia:Mentorenprogramm/Projektorganisation/Opt-in-Liste

set botpausedmentors [read [set file [open botpausedmentors]]][close $file]

if {0 || !$manual && !$forgotten} {
	set ret1 [post $dewiki {*}$get / titles $wpmp]

	#Mentorenkategorie
	foreach dict [catmem [post $dewiki {*}$catmem / cmtitle {Kategorie:Benutzer:Mentor}]] {
		lappend catmentors [set title [string map {Benutzerin: Benutzer:} [dict get $dict title]]]
	}

	#WP:MP
	foreach template [lrange [regexp -all -inline {\{\{.*?\n\}\}} [set text [content $ret1]]] 1 end] {
		regexp {\n\| *?Mentor *= *([^ ].*?)\n} $template -> mentor
		regsub { {{Anker\|.*?}}} $mentor {} mentor
		set mentor [string toupper $mentor 0 0]
		set ret14 [post $dewiki {*}$lastcontrib / ucuser $mentor]
		set active [expr {[clock add [set ts [scan-ts [lastcontrib $ret14]]] 7 days] > [clock seconds]}]
		if [regexp {\n\| *Pause *= *[Jj]a *\n} $template] {
			lappend pausedmentors $mentor
			if {$mentor in $botpausedmentors && $active} {
				regsub "(\n\\| *Mentor *= *$mentor *\n\\| *Pause *=) *(\[Jj\]a) *\n" $text "\\1 \n" text
				struct::set exclude botpausedmentors $mentor
				lappend unpausedmentors $mentor
			}
		} else { #nicht auf Pause
			if !$active {
				lappend pausedmentors $mentor
				lappend botpausedmentors $mentor
				lappend newpausedmentors $mentor
				regsub "(\n\\| *Mentor *= *$mentor *\n\\| *Pause *=) *(\[Nn\]ein)? *\n" $text "\\1 ja\n" text
			} else {
				lappend activementors $mentor
			}
		}
		lappend wpmpmentors Benutzer:$mentor
		set wpmpcomentors [dict values [regexp -all -inline {\n\| *Co-Mentor\d *= *([^\n ][^\n]+)(?=\n)} $template]]

		#Kommentare entfernen
		set wpmpcomentors2 {}
		foreach comentor $wpmpcomentors {
			if {[set comentor [string toupper [string trim [regsub {<!--.*-->} $comentor {}]] 0 0]] ne {}} {
				lappend wpmpcomentors2 $comentor
				dict lappend wpmpcomentors3 $mentor $comentor
			}
		}

		lappend comentorlist $mentor $wpmpcomentors2
		set ret3 [post $dewiki {*}$get / titles [format $utmpl $mentor] / redirects]
		if [catch {
			set tmplcomentors [dict values [regexp -all -inline {\n\| *Co-Mentor\d *= *([^\n ][^\n]+) *(?=\n)} [content $ret3]]]
			set tmplcomentors2 {}
			foreach comentor $tmplcomentors {
				if {[set comentor [string trim [regsub {<!--.*-->} $comentor {}]]] ne {}} {
					lappend tmplcomentors2 $comentor
				}
			}
			if [llength [struct::set symdiff $wpmpcomentors2 $tmplcomentors2]] {
				puts "wp:mp/utmpl @ $mentor: [lrange [struct::set intersect3 $wpmpcomentors2 $tmplcomentors2] 1 2]"
			}
		}] {
			puts "no template @ $mentor"
		}

		if ![llength $wpmpcomentors2] {
			#puts "no comentor @ $mentor"
			continue
		}

		if ![llength $wpmpcomentors3] {
			puts "no active comentor @ $mentor"
		}

		if 0 {###
		if {$wpmpcomentors2 ne [lsort $wpmpcomentors2]} {
			puts "not sorted @ wp:mp $mentor: $wpmpcomentors2"
		}
		}

		foreach comentor [lsort $wpmpcomentors2] {
			dict lappend rellist $comentor $mentor
		}

		foreach comentor [lsort $tmplcomentors2] {
			dict lappend rellist2 $comentor $mentor
		}
	}
	
	set token [login [set wiki $dewiki]]
	if {[exists newpausedmentors] || [exists unpausedmentors]} {
		if {0 || !$manual} {
			puts [edit $wpmp "Bot: [join [lmap i [list\
				[expr {[exists newpausedmentors]?"setze [join [lmap mentor $newpausedmentors {set mentor \[\[Benutzer:$mentor|\]\]}] {, }] auf Pause":{}}]\
				[expr {[exists unpausedmentors]?"entferne Pause bei [join [lmap mentor $unpausedmentors {set mentor \[\[Benutzer:$mentor|\]\]}] {, }]":{}}]
			] {expr {[string length $i]?$i:[continue]}}] {, }]" $text]
			if [exists newpausedmentors] {
				puts pause\ mentors:[join $newpausedmentors {, }]
				foreach mentor $newpausedmentors {
					if {$mentor ne {Frank Murmann}} {
					puts [edit BD:$mentor {Du wurdest im Mentorenprogramm auf Pause gesetzt} {Da du länger als 7 Tage keine Bearbeitungen getätigt hast, wurdest du automatisch im\
					 Mentorenprogramm auf Pause gesetzt. Wenn du wieder aktiv bist, werde ich in der darauffolgenden Nacht die Pause wieder beenden. – ~~~~} / section new]
					}
				}
			}
			if [exists unpausedmentors] {
				puts unpause\ mentors:[join $unpausedmentors {, }]
				foreach mentor $unpausedmentors {
					if {$mentor ne {Frank Murmann}} {
					puts [edit BD:$mentor {Deine Pause im Mentorenprogramm wurde beendet} {Da du wieder aktiv bist, habe ich deine Pause im Mentorenprogramm entfernt.\
					 Falls du weiterhin auf Pause stehen möchtest, dann trage sie bitte wieder ein (sie wird dann auch nicht wieder herausgenommen). – ~~~~} / section new]
					}
				}
			}
		}
	}

	foreach {mentor comentors} $wpmpcomentors3 {
		set wpmpcomentors4 {}
		foreach co $comentors {
			if {$co in $activementors} {
				lappend wpmpcomentors4 $co
			}
		}
		if 0 {###
		if ![llength $wpmpcomentors4] {
			puts "no active comentors: $mentor"
		}
		}
	}

	if 0 {###
	foreach mentor $catmentors {
		if {[string map {Benutzer: {}} $mentor] ni [dict keys $rellist]} {
			puts "Is not comentor of anyone: $mentor"
		}
	}
	}

	#Co-Übersicht
	lappend output {Ein in kursiver Schrift stehender Mentorenname bedeutet, dass der Mentor auf der Seite [[WP:Mentorenprogramm]] auf Pause gesetzt ist: <br/>(per Bot) wegen momentaner\
	 Inaktivität (von mindestens sieben Tagen), Urlaub, sonstiger Abwesenheit oder weil er zur Zeit keine [[:Kategorie:Benutzer:Wunschmentor gesucht|Wunschmentorengesuche]] empfangen kann\
	 oder möchte.}
	lappend output {}
	lappend output "{| class=\"wikitable sortable\""
	lappend output {! Mentor}
	lappend output {! Co-Mentor 1}
	lappend output {! Co-Mentor 2}
	lappend output {! Co-Mentor 3}
	lappend output {! Co-Mentor 4}
	foreach {mentor comentors} $comentorlist {
		set outputlist {}
		foreach comentor $comentors {
			if {$comentor in $pausedmentors} {
				lappend outputlist ''\[\[Benutzer:$comentor|\]\]''
			} else {
				lappend outputlist \[\[Benutzer:$comentor|\]\]
			}
		}
		if {[llength $outputlist] < 4} {
			append outputlist " [lrepeat [expr {4-[llength $outputlist]}] {}]"
		}
		if {$mentor in $pausedmentors} {
			set outputprepend ''\[\[Benutzer:$mentor|\]\]''
		} else {
			set outputprepend \[\[Benutzer:$mentor|\]\]
		}
		lappend output |-
		lappend output "| [join [list $outputprepend [join $outputlist { || }]] { || }]"
	}
	lappend output "|}\n"
	lappend output {[[Kategorie:Wikipedia:Mentorenprogramm|Co-Übersicht]]}

	if {0 || !$manual} {
		edit {Wikipedia:Mentorenprogramm/Co-Übersicht} {Bot: aktualisiere Liste} [join $output \n] / minor true
	}

	foreach {comentor mentors} $rellist {
		if {"Benutzer:$comentor" ni $catmentors} {
			puts "no mentor @ wp:mp $mentors: $comentor"
		}
	}

	foreach {comentor mentors} $rellist2 {
		if {"Benutzer:$comentor" ni $catmentors} {
			puts "no mentor @ utmpl $mentors: $comentor"
		}
	}

	#Wunschmentorenvorlagen
	set ret2 [post $dewiki {*}$allpages / apprefix $wmtmpl / apnamespace 4]
	foreach page [allpages $ret2] {
		regexp {/([^/]*?)$} [set title [dict get $page title]] -> mentor
		if {"Benutzer:[string toupper $mentor 0 0]" ni $catmentors && $mentor ne {Vorlage für neue Mentoren}} {
			puts "no mentor @ wmtmpl $title"
		}
	}

	if [llength [struct::set symdiff $wpmpmentors $catmentors]] {
		puts "mentordiff wpmp/cat: [lrange [struct::set intersect3 $wpmpmentors $catmentors] 1 2]"
	}

	package require uri::urn
	set ret9 [post $dewiki {*}$get / titles {Benutzer:Anka Friedrich/markMentors.js}]
	foreach jsmentor [split [lindex [regexp -inline {var mentors=new Array\((.*?)\);} [content $ret9]] 1] ,] {
		lappend jsmentors Benutzer:[string map {_ { }} [encoding convertfrom [uri::urn::unquote [string trim $jsmentor {\" }]]]]
	}
	if [llength [struct::set symdiff $jsmentors $catmentors]] {
		puts "mentordiff js/cat: [lrange [struct::set intersect3 $jsmentors $catmentors] 1 2 ]"
	}

	#Mentorenvorlagen
	source ~/library.tcl

	set dewiki_p [get-db dewiki]
	set templates [mysqlsel $dewiki_p "select page_title from page where page_title like '%/Vorlage\\_Mentor' and page_namespace = 2" -list]
	foreach template $templates {
		if {"Benutzer:[set mentor [string map {_ { } {/Vorlage_Mentor} {}} $template]]" ni $catmentors && $mentor ni {{Church of emacs/static} Reimmichl-212}} {
			puts "no mentor @ utmpl $mentor"
		}
	}
}; #if !$manual || !$forgotten

#Menteekategorie
lassign {} listduration listactivity dictactivity dictactivity2 dictduration dictduration2
set add 3; #0/3
if $all {
	set add 0
}
set wiki $dewiki
cont {ret4 {
foreach page [catmem $ret4] {
	dict with page {
		if {[set ts [clock add [scan-ts $timestamp] 12 months]] < [clock seconds]} {
			set ret6 [post $dewiki {*}$get / titles $title]
			if ![regexp {{{[Bb]enutzer(?:in)?:([^\}]*?)/(?:Vorlage[ :/_])*Mentor(?:}}|\|)} [content $ret6] -> mentor] {
				regexp {{{ *Mentee.*\| *Mentor *= *([^\n]*).*}}} [content $ret6] -> mentor
			}
			#15 monate betreut, benachrichtigung, obligatorisch
			if {[set ts2 [clock add $ts $add months]] < [clock seconds]} {
				if {[clock add $ts2 1 day] > [clock seconds]} {
					dict lappend dictduration2 $mentor \[\[$title\]\]
				}
				lappend listduration "D [format %2d [expr {[set days [expr {([clock seconds]-$ts2)/24/60**2}]]/30}]] [format %2d [expr {$days % 30}]] $mentor:\
				 [string map {Benutzer: {} Benutzerin: {}} $title]"
			#12 monate betreut, benachrichtigung, wenn gewünscht
			} elseif {[clock add $ts 1 day] > [clock seconds]} {
				dict lappend dictduration $mentor \[\[$title\]\]
			}
			set mentor {}
		}
		set ret5 [post $dewiki {*}$lastcontrib / ucuser [string map {Benutzer: {} Benutzerin: {}} $title]]
		if {[catch {
			set timestamp [lastcontrib $ret5]
			if {[set ts [clock add [scan-ts $timestamp] 2 months]] < [clock seconds]} {
				set ret6 [post $dewiki {*}$get / titles $title]
				if ![regexp {{{[Bb]enutzer(?:in)?:([^\}]*?)/(?:Vorlage[ :/_])*Mentor(?:}}|\|)} [content $ret6] -> mentor] {
					regexp {{{ *Mentee.*\| *Mentor *= *([^\n]*).*}}} [content $ret6] -> mentor
				}
				#5 monate inaktiv, austragung
				if {[set ts2 [clock add $ts $add months]] < [clock seconds]} {
					lappend listactivity "A [format %2d [expr {[set days [expr {([clock seconds]-$ts2)/24/60**2}]]/30}]] [format %2d [expr {$days % 30}]] $mentor:\
					 [string map {Benutzer: {} Benutzerin: {}} $title]"
					dict lappend dictactivity2 $mentor [string map {Benutzer: {} Benutzerin: {}} $title]
				}
				set diff 0
				set weekday 1
				if {[clock format [clock seconds] -format %d%m%Y] eq {31052011}} {
					set diff 4
					set weekday 2
				}
				if {[clock format [clock seconds] -format %d%m%Y] eq {07032015}} {
					set diff 0
				}
				#3 monate inaktiv, benachrichtigung, wenn gewünscht
				if {$mentor ne {Reinhard Kraasch} && [clock add $ts [expr {1+$diff}] day] > [clock seconds] || $mentor eq {Reinhard Kraasch} &&\
				 [clock add $ts 7 days] > [clock seconds] && [clock format [clock seconds] -format %u] == $weekday} {
						dict lappend dictactivity $mentor \[\[$title\]\]
				}
				set mentor {}
			}
		}] && $title ni {{Benutzer:Erich Hunger}}} {
			puts "timestamp error: $title $ret5"
		}
	}
}
}} {*}$catmem / cmtitle Kategorie:Benutzer:Mentee / cmprop title|timestamp

set ret8 [post $dewiki {*}$get / titles $optin / rvsection 1]
if !$manual {
	#Benachrichtigung Betreuungsdauer
	foreach {mentor mentees} $dictduration {
		if {[regexp "Benutzer(in)?:$mentor" [content $ret8]] || ![llength $mentor]} {
			puts 12:mentor:$mentor|mentees:[join $mentees]
			catch {puts [edit BD:$mentor "Benachrichtigung über Überschreitung der maximalen Betreuungszeit im Mentorenprogramm am [string map {{  } { }} [clock format [clock\
			 seconds] -format {%e. %N. %Y}]]" "[join $mentees {, }]. <small>Dies ist eine automatische Erinnerung an Mentees, deren Betreuungszeit 12 Monate oder mehr beträgt.\
			 Bitte nicht hier antworten, Antworten werden nicht gelesen.</small> – ~~~~" / section new]}
		}
	}
	foreach {mentor mentees} $dictduration2 {
		puts 15:mentor:$mentor|mentees:[join $mentees]
		catch {puts [edit BD:$mentor "Benachrichtigung über Überschreitung der maximalen Betreuungszeit im Mentorenprogramm am [string map {{  } { }} [clock format [clock seconds]\
		 -format {%e. %N. %Y}]]" "[expr {[llength $mentees]==1?{Folgender Mentee hat}:{Folgende Mentees haben}}] die maximale Betreuungszeit von 15 Monaten überschritten und [expr\
		 {[llength $mentees]==1?{sollte}:{sollten}}] aus dem Mentorenprogramm entlassen werden: [join $mentees {, }]. – ~~~~" / section new]}
	}
}
if !$forgotten {
	foreach item [concat [lsort -decreasing $listduration] [lsort -decreasing $listactivity]] {
		if {[string first "\[\[Benutzer:[set mentor [lindex [regexp -inline { *\d*  *\d* ([^:]+)} $item] 1]]" [content $ret8]] >= 0 || ![llength $mentor]} {
			puts \ $item
		} else {
			puts ($item)
		}
	}
}

#Automatisches Archivieren
set dict {}
if {!$manual && !$forgotten} {
	foreach {mentor mentees} $dictactivity2 {
		if {$mentor in {Codc}} {
			continue
		}
		set list {}
		foreach mentee $mentees {
			if {$mentee in {}} {
				continue
			}
			set text [content [post $dewiki {*}$get / titles Benutzer:$mentee]]
			if [regsub {{{Benutzer(in)?:[^\}]*?/Vorlage[ _]Mentor}}\n?} $text {} text] {
				puts [edit Benutzer:$mentee −mp $text]
				puts [edit BD:$mentee [set summary {{{ers:ArchivMentee2}}}] {} / appendtext \n$summary / minor true]
				dict lappend dict $mentor $mentee
			} else {
				puts "archive/wrong template: $mentor/$mentee"
			}
		}
	}
	foreach {mentor list} $dict {
		puts [edit BD:$mentor [set summary "{{ers:Aus Mentorenprogramm (Benachrichtigung)|[join $list |]}}"] {} / appendtext \n$summary / minor true]
	}
}

if $manual return

#Benachrichtigung Aktivität
if $forgotten {
	set token [login [set wiki $dewiki]]
	foreach {mentor mentees} [lsort -stride 2 $dictactivity] {
		if {[regexp "Benutzer(in)?:$mentor" [content $ret8]] || ![llength $mentor]} {
			catch {puts [edit BD:$mentor "Benachrichtigung über inaktive Mentees am [string map {{  } { }} [clock format [clock seconds] -format {%e. %N. %Y}]]" "[join $mentees\
			 {, }]. <small>Dies ist eine automatische Erinnerung an Mentees, die 2 Monate oder länger inaktiv sind. Bitte nicht hier antworten, Antworten werden nicht\
			 gelesen.</small> – ~~~~" / section new]}
		}
	}
	return
}
foreach {mentor mentees} $dictactivity {
	if {[regexp "Benutzer(in)?:$mentor" [content $ret8]] || ![llength $mentor]} {
		if !$manual {
			puts 2:mentor:$mentor|mentees:[join $mentees]
			catch {puts [edit BD:$mentor "Benachrichtigung über inaktive Mentees am [string map {{  } { }} [clock format [clock seconds] -format {%e. %N. %Y}]]" "[join $mentees\
			 {, }]. <small>Dies ist eine automatische Erinnerung an Mentees, die 2 Monate oder länger inaktiv sind. Bitte nicht hier antworten, Antworten werden nicht\
			 gelesen.</small> – ~~~~" / section new]}
		} else {
			puts "due: $mentor: [join $mentees {, }]."
		}
	}
}

#Mailingliste
set ret7 [post $dewiki {*}$get / titles Wikipedia:Mentorenprogramm/Mailingliste / rvsection 1]
foreach {-> mentor} [regexp -all -inline {# \[\[Benutzer(?:in)??:(.*?)\|.*?\]\]} [content $ret7]] {
	if {"Benutzer:[string toupper $mentor 0 0]" ni $catmentors} {
		puts "no mentor @ ml: $mentor"
	}
}

#Co-Mentoren bei WM-Gesuchen benachrichtigen
set ret10 [post $dewiki {*}$catmem / cmtitle {Kategorie:Benutzer:Wunschmentor gesucht}]
set ret13 [post $dewiki {*}$get / titles $optin / rvsection 2]
foreach item [catmem $ret10] {
	set ret12 [post $dewiki {*}$get / titles [set title [dict get $item title]]]
	regexp {{{Mentor gesucht\|(.*?)(\|ja){0,1}}}} [content $ret12] -> wm notified
	if [llength $notified] {
		set ret11 [post $dewiki {*}$query / titles $title / prop categories / clprop timestamp]
		if {[clock add [set ts [scan-ts [dict get [lindex [page $ret11 categories] 0] timestamp]]] 1 day] < [clock seconds] && [clock add $ts 2 days] > [clock seconds]} {
			set ret3 [post $dewiki {*}$get / titles [apply {{mentor} {
				global utmpl
				if {$mentor eq {Hannes Röst}} {
					return {Benutzer:Hannes Röst/Vorlage/Mentor}
				} else {
					return [format $utmpl $mentor]
				}
			}} $wm] / redirects]
			set tmplcomentors [dict values [regexp -all -inline {\n\| *Co-Mentor\d *= *([^\n ][^\n]+) *(?=\n)} [content $ret3]]]
			set tmplcomentors2 {}
			foreach comentor $tmplcomentors {
				if {[set comentor [string trim [regsub {<!--.*-->} $comentor {}]]] ne {}} {
					lappend tmplcomentors2 $comentor
				}
			}
			set debug true
			foreach co $tmplcomentors2 {
				edit BD:$co "\[\[$title|\]\] wünscht sich $wm als Mentor" {Das Wunschmentorengesuch blieb seit einem Tag unbearbeitet, schau doch bitte mal, was du als\
				 Co-Mentor machen kannst. – ~~~~} / section new
				if {[string first "$co" [content $ret13]] >= 0} {
					post $dewiki {*}$token {*}$email / target $co / subject "Wikipedia: $title wünscht sich $wm als Mentor" / text "Das Wunschmentorengesuch blieb seit\
					 einem Tag unbearbeitet, schau doch bitte mal, was du als Co-Mentor machen kannst. Du erhältst diese Nachricht, weil du in $optin eingetragen bist.\
					 Wenn du diese E-Mails nicht mehr erhalten möchtest, kannst du dich dort austragen."
				}
			}
			unset debug
		}
	}
}

puts -nonewline [set file [open botpausedmentors w]] $botpausedmentors
