#!/data/project/shared/tcl/bin/tclsh8.7

# Copyright 2019 Giftpflanze

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
package require struct::set

source ../library.tcl

set dewiki [get-db dewiki]
set wppath https://de.wikipedia.org/wiki/
set namespaces {0 {} 1 Diskussion 2 Benutzer 3 {Benutzer Diskussion} 4 Wikipedia 5 {Wikipedia Diskussion} 6 Datei 7 {Datei Diskussion} 8 MediaWiki 9 {MediaWiki Diskussion} 10 Vorlage\
 11 {Vorlage Diskussion} 12 Hilfe 13 {Hilfe Diskussion} 14 Kategorie 15 {Kategorie Diskussion} 100 Portal 101 {Portal Diskussion} 828 Modul 829 {Modul Diskussion}}

proc cat {cat recursive {catonly 0}} {
	global dewiki visited
	set return {}
	foreach {ns title type} [mysqlsel $dewiki "select page_namespace, page_title, cl_type from categorylinks, page where cl_from = page_id and cl_to = '[mysqlescape $cat]'" -flatlist] {
		if {($type eq {page} && !$catonly) || ($type eq {subcat} && $catonly)} {
			lappend return [list $ns [string map {_ { }} $title]]
		}
		if {$type eq {subcat} && $recursive && $title ni $visited} {
			lappend visited $title
			lappend return {*}[cat $title $recursive $catonly]
		}
	}
	return $return
}

while {[FCGI_Accept] >= 0} {
	if [catch {
		ncgi::header {text/html; charset=utf-8}
		ncgi::reset
		ncgi::input
		ncgi::setDefaultValue sub 0
		ncgi::importAll source sort sub
		lassign {} visited sourcepages sortcats
		head ! {
			title - [set title {Seiten einer Kategorie anhand der Unterkategorien einer anderen Kategorie sortieren}]
			link rel=stylesheet href=weblinksuche.css media=screen -
		}
		body ! {
			h1 + $title
			div ! {
				form method=get action=$env(SCRIPT_NAME) ! {
					fieldset ! {
						div ! {
							label for=source - Quellkategorie:
							put {&nbsp;}
							input name=source size=50 value=$source -
							put {&nbsp;}
							input name=sub type=checkbox value=1 {*}[expr {$sub?{checked=}:{}}] -
							put {&nbsp;}
							label for=sub - Unterkategorien
						}
						div ! {
							label for=sort - Sortierkategorie:
							put {&nbsp;}
							input name=sort size=50 value=$sort -
						}
						div ! {
							input type=submit value=Sortieren -
						}
					}
				}
				if {[string length $source] && [string length $sort]} {
					if [catch {
						set sourcepages [cat [string map {{ } _} $source] $sub]
						set sortcats [lmap {- cat} [join [cat [string map {{ } _} $sort] 0 1]] {set cat}]
					}] {
						after 300000
						exit
					}
					div ! {
						ul ! {
							foreach cat [lsort $sortcats] {
								li - $cat
								ul ! {
									foreach {ns title} [join [lsort [struct::set intersect $sourcepages [cat [string map {{ } _} $cat] 0]]]] {
										li - [a href=${wppath}[uri::urn::quote [set title [set ns [dict get $namespaces $ns]][expr {[llength\
										 $ns]?{:}:{}}]$title]] . [string map {_ { }} $title]]
									}
								}
							}
						}
					}
				}
			}
		}
	}] {
		pre - $errorInfo
	}
}
