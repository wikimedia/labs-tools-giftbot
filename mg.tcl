#!/data/project/shared/tcl/bin/tclsh8.7

# mpbot

# “Mentor gesucht” IRC script

# Copyright 2010, 2011, 2012 Giftpflanze

# mpbot is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.

package require struct::set

source api.tcl
source dewiki.tcl
source irc.tcl

set quiet true
set channel wikipedia-de-mp
set optin {Wikipedia:Mentorenprogramm/Projektorganisation/Opt-in-Liste}

foreach array {oldlist newlist} {
	array set $array {1 {} 2 {}}
}

set fnh [register-lc $channel {{sender - recipient message} {
	global fnh newlist channel
	if {$message eq {%status}} {
		if {$recipient ne "#$channel"} {
			set recipient $sender
		}
		if [llength $newlist(1)] {
			puts $fnh "PRIVMSG $recipient :Mentorengesuche: [join $newlist(1) {, }]"
		}
		if [llength $newlist(2)] {
			puts $fnh "PRIVMSG $recipient :Wunschmentorengesuche: [join $newlist(2) {, }]"
		}
		if {![llength $newlist(1)] && ![llength $newlist(2)]} {
			puts $fnh "PRIVMSG $recipient :Liste ist leer"
		}
	}
}}]

register-rc de.wikipedia {{- - title args} {
	global dewiki catmem get format fnh oldlist newlist wiki token optin lastcontrib channel emailuser
	if [regexp ^Benutzer(in)?: $title] {
		array set newlist {1 {} 2 {}}
		foreach {no category} {2 {Kategorie:Benutzer:Wunschmentor gesucht} 1 {Kategorie:Benutzer:Mentor gesucht}} {
			set ret [post $dewiki {*}$catmem / cmtitle $category]
			foreach item [catmem $ret] {
				if {[dict get $item ns] != 2} {
					puts $fnh "Ungültiger Namensraum: \[\[[dict get $item title]\]\]"
				} else {
					lappend newlist($no) [dict get $item title]
				}
			}
			lassign [struct::set intersect3 $oldlist($no) $newlist($no)] -> dellist($no) addlist($no)
			switch $no \
			1 {
				foreach item $addlist($no) {
					lappend neulist($no) \[\[$item\]\]
					if [regexp {\{\{.*?/Vorlage Mentor\}\}} [content [post $dewiki {*}$get / titles $item]]] {
						lappend neulist($no) "bereits betreut"
					}
				}
				if [llength $addlist($no)] {
					puts $fnh "PRIVMSG #$channel :Neue Mentorengesuche: [join $neulist($no) {, }]"
				}
			} 2 {
				set neulist($no) {}
				foreach item $addlist($no) {
					set ret1 [post $dewiki {*}$get / titles $item]
					if ![regexp {{{Mentor gesucht\|(.*?)(\|ja){0,1}}}} [set text [content $ret1]] -> wm notified] {
						continue
					}
					if {$item in $newlist(1)} {
						regsub {\{\{Mentor gesucht\}\}} $text {} text
					}
					if [catch {set tsdiff [expr [clock seconds] - [scan-ts [lastcontrib [post $dewiki {*}$lastcontrib / ucuser $wm]]]]}] {
						puts $fnh "PRIVMSG #$channel :Ungültiger Wunschmentor@$item: $wm"
						continue
					}
					if ![llength $notified] {
						lappend neulist($no) "\[\[$item\]\] für $wm (letzte Bearbeitung vor [expr [scan [clock format $tsdiff -format %j] %d] - 1] Tagen, [clock format\
						 $tsdiff -format {%H Stunden, %M Minuten und %S Sekunden}])"
						if ![regexp {\{\{.*?/Vorlage Mentor\}\}} $text] {
							set token [login [set wiki $dewiki]]
							puts [set ret3 [edit $item {Bot: Wunschmentor wird benachrichtigt} [regsub {({{Mentor gesucht\|.*?)(}})} $text {\1|ja\2}] / minor true]]
							if ![dict exists $ret3 edit nochange] {
								puts [edit BD:$wm "\[\[$item|\]\] wünscht sich dich als Mentor" {Ein Mentee hat dich als Wunschmentor angegeben. – ~~~~} / section new]
							}
							if {[string first "\[\[Benutzer:$wm|" [content [post $dewiki {*}$get / titles $optin / rvsection 2]]] >= 0} {
								puts [post $dewiki {*}$token {*}$emailuser / target $wm / subject "Wikipedia: $item wünscht sich dich als Mentor" / text "Du\
								 erhältst diese Nachricht, weil du in $optin eingetragen bist.  Wenn du diese E-Mails nicht mehr erhalten möchtest, kannst du\
								 dich dort austragen."]
							}
						} else {
							lappend neulist($no) "bereits betreut"
						}
					}
					unset wm
				}
				if [llength $neulist($no)] {
					puts $fnh "PRIVMSG #$channel :Neue Wunschmentorengesuche: [join $neulist($no) {, }]"
				}
			}
			foreach item $dellist($no) {
				set ret2 [post $dewiki {*}$get / titles $item]
				set mentor {}
				catch {
					if ![regexp {{{Benutzer(?:in)*:([^\}]*?)/(?:Vorlage[ :/_])*Mentor}}} [content $ret2] -> mentor] {
						regexp {{{ *Mentee.*\| *Mentor *= *([^\n]*).*}}} [content $ret2] -> mentor
					}
				}
				if ![llength $mentor] {
					lappend erllist($no) "$item aus Kategorie entfernt"
				} else {
					lappend erllist($no) "$item von $mentor"
				}
			}
			if [llength $dellist($no)] {
				puts $fnh "PRIVMSG #$channel :erledigt: [join $erllist($no) {, }]"
			}
			set oldlist($no) $newlist($no)
		}
	}
}}

vwait exit
