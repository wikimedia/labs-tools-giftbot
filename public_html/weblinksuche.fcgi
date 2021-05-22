#!/data/project/shared/tcl/bin/tclsh8.7

# Special:LinkSearch (Spezial:Weblinksuche) with namespace filtering for
# dewiki

# Copyright 2013, 2014 Giftpflanze

# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.

package require Fcgi
package require htmlgen
namespace import htmlgen::*
package require ncgi
package require uri::urn
package require http

source ../library.tcl

set dewiki [get-db dewiki]
set wppath https://de.wikipedia.org/wiki/

set namespaces_common {
	1 Diskussion 2 Benutzer 3 {Benutzer Diskussion}
	4 Wikipedia 5 {Wikipedia Diskussion} 6 Datei 7 {Datei Diskussion}
	8 MediaWiki 9 {MediaWiki Diskussion} 10 Vorlage 11 {Vorlage Diskussion}
	12 Hilfe 13 {Hilfe Diskussion} 14 Kategorie 15 {Kategorie Diskussion}
	100 Portal 101 {Portal Diskussion} 828 Modul 829 {Modul Diskussion}
}
set namespaces_list [list {} alle 0 (Artikel-) {*}$namespaces_common]
set namespaces_lookup [list 0 {} {*}$namespaces_common]

proc paging_header {query resultnum limit offset} {
	global env
	p ! {
		put Zeige (
		set link [expr {$limit==1?{vorheriger}:"vorige $limit"}]
		if $offset {
			a href=$env(SCRIPT_NAME)?limit=$limit&offset=[expr {$offset-$limit}]&$query - $link
		} else {
			put $link
		}
		put { | }
		set link [expr {$limit==1?{nächster}:"nächste $limit"}]
		if {$resultnum < $limit} {
			put $link
		} else {
			a href=$env(SCRIPT_NAME)?limit=$limit&offset=[expr {$offset+$limit}]&$query - $link
		}
		put ) (
		foreach num {20 50 100 250 500} {
			lappend list [a href=$env(SCRIPT_NAME)?limit=$num&offset=$offset&$query . $num]
		}
		put [join $list { | }])
	}
}

while {[FCGI_Accept] >= 0} {
	if [catch {
		ncgi::header {text/html; charset=utf-8}
		ncgi::reset
		ncgi::input
		ncgi::setDefaultValue associated 0
		ncgi::setDefaultValue offset 0
		ncgi::setDefaultValue limit 100
		ncgi::importAll target namespace associated offset limit
		set query [http::formatQuery target $target namespace $namespace associated $associated]
		head ! {
			title - [set title {Weblinksuche – nach Namensräumen eingrenzbar}]
			link rel=stylesheet href=weblinksuche.css media=screen -
		}
		body ! {
			h1 - $title
			div ! {
				p - Dieses Tool ermöglicht, analog zu [a href=${wppath}[set link Spezial:Weblinksuche] $link], die Suche\
					nach Seiten, in denen bestimmte Weblinks enthalten sind, allerdings kann die Suche auch nach\
					Namensräumen gefiltert werden und es wird die Gesamtanzahl der gefundenen Links angegeben.
				p - Als Platzhalter können [code . %] und [code . _] benutzt werden. Dabei steht [code . %] für mehrere\
					(auch null) Zeichen und [code . _] für genau 1 Zeichen (Beispiele: [code\
					http://%.wikipedia.org/wiki/%], [code http://www.wiki_edia.org/]). Sollen die Zeichen [code . %]\
					oder [code . _] Teil der URL sein, müssen sie mit [code . \\] maskiert werden (Beispiele: [code\
					http://de.wikipedia.org/wiki/\\%25-Darstellung], [code\
					http://de.wikipedia.org/wiki/Erster\\_Weltkrieg]).
				p - Das Protokoll muss immer mit angegeben werden (es gibt aber auch protokollrelative URLs, die mit [code\
					//] beginnen). Ist die URL am Ende nicht vollständig, muss sie mit einem Prozentzeichen\
					abgeschlossen werden.
				form method=get action=$env(SCRIPT_NAME) ! {
					fieldset ! {
						label for=target - Suchmuster:
						put {&nbsp;}
						input name=target size=50 value=$target -
						put {&nbsp;}
						label for=namespace - Namensraum:
						put {&nbsp;}
						select name=namespace ! {
							foreach {value ns} $namespaces_list {
								option value=$value {*}[expr {$value==$namespace?{selected=}:{}}] - $ns
							}
						}
						put {&nbsp;}
						input name=associated type=checkbox value=1 {*}[expr {$associated?{checked=}:{}}] -
						put {&nbsp;}
						label for=associated - {Zugehöriger Namensraum}
						put {&nbsp;}
						input type=submit value=Suchen -
					}
				}
				if [string length $target] {
					if [catch {
						set expressions {distinct el_to, page_namespace, page_title}
						set conditions\
						"from externallinks, page\
						where el_from = page_id\
						and el_to like '[mysqlescape $target]'\
						[expr {
							[string length $namespace]
							? (
								$associated
								? "and page_namespace in ([expr {
									[mysqlescape $namespace]/2*2
								}], [expr {
									[mysqlescape $namespace]/2*2+1
								}])"
								: "and page_namespace = [mysqlescape $namespace]"
							)
							: {}
						}]"
						set modifiers "limit [mysqlescape $limit] offset [mysqlescape $offset]"
						foreach var {count resultnum} query [list\
							"count($expressions) $conditions"\
							"$expressions $conditions $modifiers"\
						] option -list {
							set $var [mysqlsel $dewiki "select $query" {*}$option]
						}
					}] {
						after 300000; # 5 minute restart throttle
						exit
					}
					div ! {
						if $resultnum {
							set resultnum [expr {min($resultnum,$limit)}]
							p - Hier [expr {$resultnum==1?{ist}:{sind}}] [b . $resultnum] von $count [expr\
								{$count==1?{Ergebnis}:{Ergebnissen}}], beginnend mit Nummer [b [expr\
								{$offset+1}].]
							paging_header $query $resultnum $limit $offset
							ol start=[expr {$offset+1}] ! {
								mysqlmap $dewiki {to ns title} {
									li - [a href=$to $to] ist verlinkt von [a\
										href=${wppath}[uri::urn::quote [set title [set ns [dict get\
										$namespaces_lookup $ns]][expr {[llength\
										$ns]?{:}:{}}]$title]] . [string map {_ { }} $title]]
								}
							}
							paging_header $query $resultnum $limit $offset
						} else {
							p - Es sind aktuell keine zutreffenden Einträge vorhanden.
						}
					}
				}
			}
			div - [p [a href=https://gerrit.wikimedia.org/r/plugins/gitiles/labs/tools/giftbot/+/master/public_html/weblinksuche.fcgi Quelltext]]
		}
	}] {
		pre - $errorInfo
	}
}
