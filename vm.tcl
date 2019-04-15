#!/data/project/shared/tcl/bin/tclsh8.7

# vmppbot – VM page protect bot

# Mark VM sections as done when the according pages are protected

# Idea by IWorld

# Copyright 2010, 2011, 2012, 2014, 2016 Giftpflanze

# vmppbot is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl
source irc.tcl

#set env(JOB_NAME) vm; #
#set env(JOB_ID) [pid]; #
#set debug true; #
set quiet true
set watchlist {}
set token [login [set wiki $dewiki]]
set firstrun true
set srcpage Wikipedia:Vandalismusmeldung

register-rc de.wikipedia {{- - title action - user - comment} {
	global dewiki get logevents watchlist firstrun srcpage
	if {$firstrun || $title eq $srcpage && $user ni {GiftBot SpBot Xqbot} || $action in {protect modify} && [regexp {\[\[(.*) \u200e} $comment -> title] && $title in $watchlist} {
		set firstrun false
		do {
			lassign {} watchlist buffer
			set ret1 [post $dewiki {*}$get / rvprop content|timestamp / titles $srcpage]
			regexp {(.*?)(==.*)?$} [content $ret1] -> buffer sections
			foreach {section heading body} [regexp -all -inline {==(.*?)==(\n.*)(?===|$)} $sections] {
				if {!([regexp {\(erl\.\)|\(erledigt\)} $heading] || [regexp {Benutzer(in)*(:|\|)} $heading]\
				 || [regexp {(\d{1,3}\.){3}\d{1,3}|([[:xdigit:]]{0,4}:){7}[[:xdigit:]]{1,4}} $heading]) && [regexp {\[\[(.*?)\]\]} $heading -> page]} {
					set page [string map {\u200e {} _ { }} $page]
					set page [string trim $page]
					set page [string trimleft $page :]
					set ret2 [post $dewiki {*}$logevents / letype protect / letitle $page / lelimit 1]
					if {[llength [logevents $ret2]] && [logevents $ret2 action] in {protect modify} &&
					 [clock add [set ts [scan-ts [logevents $ret2 timestamp]]] 10 minutes] > [clock seconds]} {
						append buffer "== $heading (erl.) ==$body<div style='clear:both;padding:0 5px 0 15px; border-left: 2px green solid;border-right:2px green\
						 solid;'>\[\[[expr {[regexp {^Kategorie:} $page]?":$page":$page}]\]\] wurde von {{ers:noping[string repeat |[logevents $ret2 user] 2]}} am\
						 [string map {Mrz. Mär. Mai. Mai} [clock format $ts -format {%d. %b. %Y, %H:%M} -locale de -timezone Europe/Berlin]] geschützt, [logevents\
						 $ret2 params description], Begründung: ''[expr {[set ret [logevents $ret2 comment]] eq {} ? {[keine angegeben]} : $ret}]'' – ~~~~</div>\n\n"
						lappend summary $page
					} else {
						append buffer $section
						lappend watchlist $page
					}
				} else {
					append buffer $section
				}
			}
			if [exists summary] {
				puts [set ret3 [edit $srcpage "erledigt: [join $summary {, }]" $buffer / basetimestamp [revision $ret1 timestamp] / starttimestamp [revision $ret1 timestamp]\
				 / minor true][unset summary]]
			} else {
				break
			}
		} while {[dict exists $ret3 error code] && [dict get $ret3 error code] eq {editconflict}}
	}
}}

vwait exit
