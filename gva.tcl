#!/data/project/shared/tcl/bin/tclsh8.7

# gvabot

# Cleanup of the German Wikipedia FlaggedRevisions requests page

# Copyright 2010, 2011, 2012, 2013, 2014, 2017 Giftpflanze

# gvabot is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl
source irc.tcl
source library.tcl

set bot false
set quiet true
set dbh [get-db dewiki]
set token [login [set wiki $dewiki]]

set page {Wikipedia:Gesichtete Versionen/Anfragen}

set watchlist {}
set firstrun true

register-rc de.wikipedia {{channel - title action - user - comment} {
	global page self watchlist dewiki get flagged firstrun dbh
	if {$firstrun || $channel eq {de.wikipedia} && ($title eq $page && $user ne $self || $title in $watchlist || $action in {approve approve-i} &&\
	 [regexp {\[\[02(.*)10\]\]} $comment -> title] && $title in $watchlist)} {
		set firstrun false
		do {
			lassign {} newsections watchlist
			set ret1 [post $dewiki {*}$get / rvprop content|timestamp|comment / titles $page]
			regexp {(.*?)([^\n]*?==.*)?$} [content $ret1] -> header sections
			foreach {-> section} [regexp -all -inline {([^\n]*?== .*? ==\n.*)(?=[^\n]*?==|$)} $sections] {
				set title {}
				regexp {\{\{Sichten\|(.*?)\}\}.*?} $section -> title
				if {$title eq {}} {
					continue
				}
				if {![regexp {\[\[(.*?)\|(.*?)\]\]} $section -> link text] || ![regexp {(?:[Bb]enutzer(?:in)*|[Uu]ser|Benutzer(?:in)*[ _]Diskussion|BD|user\
				talk|Spezial:Beiträge/):*(.*)$} $link -> user] && ![regexp {(?:(?:link|verweis)=Benutzer(?:Diskussion)*:)([^|]*)(?=$|\|)} $text -> user] || [regexp /\
				$user]} {
					set user {}
					#puts usererror:$section
				}
				set title [string map {\n {} _ { }} $title]; #make invalid titles right
				set ret2 [post $dewiki {*}$flagged / titles $title]
				set ret4 [post $dewiki {*}$flagged / titles $title / redirects]
				if {{missing} ni [dict keys [page $ret2]] && {invalid} ni [dict keys [page $ret2]] && {special} ni [dict keys [page $ret2]]} {
					mysqlping $dbh
					set ret5 [mysqlsel $dbh "select fp_reviewed, fp_pending_since from flaggedpages where fp_page_id=[mysqlescape [page $ret2 pageid]]" -flatlist]
					set ret6 [mysqlsel $dbh "select fp_reviewed, fp_pending_since from flaggedpages where fp_page_id=[mysqlescape [page $ret4 pageid]]" -flatlist]
					set title [page $ret2 title]
					if {![llength $ret5] && ![llength $ret6] || [llength $ret5] && [lindex $ret5 0] && ![llength $ret6] || ![llength $ret5] && [llength $ret6] &&\
					[lindex $ret6 0]} {
						#unreviewed
						puts unreviewed:$user
						if [llength $user] {
							if [regexp ^Benutzer(in)?:$user/ $title] {
								puts [edit BD:$user {Dein Eintrag auf [[Wikipedia:Gesichtete Versionen/Anfragen]]}\
								"{{subst:GESCHLECHT:{{subst:SEITENNAME}}|Lieber|Liebe|Hallo}} {{subst:SEITENNAME}},<br>ich habe deinen Eintrag \[\[:$title\]\]\
								auf \[\[Wikipedia:Gesichtete Versionen/Anfragen\]\] entfernt, da sie im Benutzernamensraum nicht gesichtet werden kann. Sie muss\
								erst in den Artikelnamensraum verschoben werden. Stelle 24 Stunden nach der Verschiebung ggf. einen weiteren Sichtungsantrag.\
								– ~~~~" / section new / redirect true]
							} else {
								puts [edit BD:$user {Dein Eintrag auf [[Wikipedia:Gesichtete Versionen/Anfragen]]}\
								"{{subst:GESCHLECHT:{{subst:SEITENNAME}}|Lieber|Liebe|Hallo}} {{subst:SEITENNAME}},<br>ich habe deinen Eintrag \[\[:$title\]\]\
								auf \[\[Wikipedia:Gesichtete Versionen/Anfragen\]\] entfernt, da die Seite über keine gesichteten Versionen verfügt und daher\
								erstgesichtet werden muss. Deine Seite taucht auf \[\[Spezial:Ungesichtete Seiten\]\] auf und wird sicher bald von einem eifrigen\
								\[\[Wikipedia:Wikipedianer|Wikipedianer\]\] gesichtet. – ~~~~" / section new / redirect true]
							}
						}
						lappend summary "\[\[$title\]\] entfernt (Erstsichtung erforderlich)"
					} elseif {[llength $ret5] && [llength $ret6] && [lindex $ret5 0] && [lindex $ret6 0]} {
						#reviewed
						lappend summary "\[\[$title\]\] erledigt"
					} elseif {[llength $ret5] && ![lindex $ret5 0] || [llength $ret6] && ![lindex $ret6 0]} {
						#oldreviewed
					    set ts [clock format [clock add [clock seconds] -1 day] -format %Y%m%d%H%M%S]
					    if {$title ni $watchlist} {
						if {[llength $ret5] && ([lindex $ret5 1] eq {} || [lindex $ret5 1] < $ts) || [llength $ret6] && ([lindex $ret6 1] eq {} || [lindex $ret6 1] < $ts)} {
							lappend newsections $section
						} else {
							#too early
							if ![regexp {time:YmdHis} $section] {
								puts delayed:$user
								if [llength $user] {
									puts [edit BD:$user {Dein Eintrag auf [[Wikipedia:Gesichtete Versionen/Anfragen]]}\
									"{{subst:GESCHLECHT:{{subst:SEITENNAME}}|Lieber|Liebe|Hallo}} {{subst:SEITENNAME}},<br>ich habe deinen Eintrag\
									\[\[:$title\]\] auf \[\[Wikipedia:Gesichtete Versionen/Anfragen\]\] versteckt, da die älteste ungesichtete Version\
									noch nicht älter als 1 Tag ist. Warte bitte, ein eifriger \[\[Wikipedia:Wikipedianer|Wikipedianer\]\] wird die Seite\
									sicher bald sichten. – ~~~~" / section new / redirect true]
								}
								lappend newsections "{{#ifexpr: {{#time:YmdHis|-1 day}} > [lindex $ret5 1]|$section|(Eintrag „$title“ versteckt)}}\n"
								lappend summary "\[\[$title\]\] versteckt (24-Stunden-Frist)"
							} else {
								lappend newsections $section
							}
						}
						lappend watchlist $title
						if {$title ne [set title [page $ret4 title]]} {
							lappend watchlist $title
						}
					    }
					}
				} else {
					#missing page or invalid title or special page
					if [catch {
						if {[clock scan [join [regexp -inline {[0-9]{2}:[0-9]{2}, [0-9]{1,2}\. (?:(?:Jan|Feb|Mär|Apr|Jun|Jul|Aug|Sep|Okt|Nov|Dez)\.*|Mai)\
						[0-9]{4} \(CES{0,1}T\)} $section]] -format {%H:%M, %d. %b. %Y (%Z)} -timezone Europe/Berlin -locale de] >= [clock add [clock seconds]\
						-6 hours]} {
							if {![regexp {<!--benachrichtigt-->} $section] && ![regexp "\{\{Kasten" $section]} {
								puts missing/invalid:$user
								if [llength $user] {
									puts [edit BD:$user {Dein Eintrag auf [[Wikipedia:Gesichtete Versionen/Anfragen]]}\
									"{{subst:GESCHLECHT:{{subst:SEITENNAME}}|Lieber|Liebe|Hallo}} {{subst:SEITENNAME}},<br>Schaue bitte einmal bei\
									\[\[Wikipedia:Gesichtete Versionen/Anfragen\]\] vorbei. Etwas bei deinem Eintrag \[\[:$title\]\] ist schief gelaufen,\
									bitte korrigiere ihn und achte auf das Intro. Somit kann dein Artikel bald von einem\
									\[\[Wikipedia:Wikipedianer|Wikipedianer\]\]\ \[\[Wikipedia:Gesichtete Versionen|gesichtet\]\] werden. – ~~~~" /\
									section new / redirect true]
									append section "<!--benachrichtigt-->\n"
									lappend summary "$user benachrichtigt (\[\[$title\]\])"
								}
							}
							lappend newsections $section
						} else {
							lappend summary "\[\[$title\]\] entfernt"
						}
					}] then {
						lappend newsections $section
					}
				}
			}
			if [exists summary] {
				if ![llength $newsections] {
					lappend summary {jetzt leer}
				}
				puts [set ret3 [edit $page [join $summary {, }] "$header[join $newsections {}]" / minor true / basetimestamp [revision $ret1 timestamp]\
				 / starttimestamp [revision $ret1 timestamp]]][unset summary]
			}
		} while {[exists ret3] && [dict exists $ret3 error code] && [dict get $ret3 error code] eq {editconflict}}
	}
}}

vwait exit
