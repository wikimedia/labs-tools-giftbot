#!/data/project/shared/tcl/bin/tclsh8.7

# autoarchiv-n.tcl

# ArchivBot replacement (dewiki)
# Archiver replacement (dewikinews)

# Copyright 2011, 2012 Giftpflanze

# autoarchiv-n.tcl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.

source api.tcl
source dewikinews.tcl

set token [login [set wiki $dewikinews]]

proc parsesection {section} {
	foreach ts [regexp -all -inline {[0-9]{2}:[0-9]{2}, [0-9]{1,2}\. (?:(?:Jan|Feb|Mär|Apr|Jun|Jul|Aug|Sep|Okt|Nov|Dez)\.*|Mai) [0-9]{4} \(CES{0,1}T\)} $section] {
		if [catch {set ts [clock scan $ts -format {%H:%M, %d. %b. %Y (%Z)} -timezone Europe/Berlin -locale de]}] {
			if [catch {set ts [clock scan $ts -format {%H:%M, %d. %b %Y (%Z)} -timezone Europe/Berlin -locale de]}] {
				puts error:$ts
			}
		}
		lappend list $ts
	}
	if ![exists list] {
		return
	}
	set list [lsort -unique $list]
	return [list [lindex $list 0] [lindex $list end] [llength $list]]
}

proc expanddest {dest ts} {
	string map {{  } { }} [clock format $ts -timezone Europe/Berlin -locale de -format $dest]
}

cont {ret1 {
	foreach item [embeddedin $ret1] {
		set ret2 [content [post $wiki {*}$get / titles [set title [dict get $item title]]]]
		#blacklist
		#if {$title in {}} {
		#	continue
		#}
		if ![regexp {{{\n*(Vorlage:)*[Aa]utoarchiv[ \n]*\|[^\{\}]*(?:{{[^\{\}]*}}[^\{\}]*)*}}} $ret2 template] {
			puts template:$title
			puts ...
			continue
		}

		regsub -all {<!--.*?-->} $template {} template
		regexp {Alter *= *([^|\}\n]*?)} $template -> age
		if ![regexp {Ziel *= *([^|\}\n]*?)} $template -> dest] {
			puts !dest:$title
			puts ...
			continue
		}
		set dest [string trim $dest]
		set minedits 1
		regexp {Mindestbeiträge *= *([^|\}\n]*?)} $template -> minedits
		set minsections 0
		regexp {Mindestabschnitte *= *([^|\}\n]*?)} $template -> minsections
		set header {{{Archiv}}}
		regexp {Kopfvorlage *= *([^|\n]*?)} $template -> header

		set topsections 0
		set offset 0
		set worklist {}
		set bug false
		set ret3 [post $wiki {*}$format / action parse / prop sections / page $title]
		foreach item2 [set sections [get $ret3 parse sections]] {
			incr offset
			dict with item2 {
				if {$fromtitle eq {false}} {
					set bug true
				}
				if {$byteoffset ne {null} && $level == 2} {
					incr topsections
					set sebmode false
					set offset2 $offset
					foreach item3 [lrange $sections $offset end] {
						if {[dict get $item3 level] != 2 || [dict get $item3 byteoffset] eq {null}} {
							incr offset2
						} else {
							break
						}
					}
					set ret4 [parsesection [set section [string range $ret2 $byteoffset [set byteoffset2 [
						expr {([lindex $sections $offset2] ne {} && [dict get [lindex $sections $offset2] byteoffset] ne {null})?
						 [dict get [lindex $sections $offset2] byteoffset]-1:{end}}
					]]]]]
					if {[lindex $ret4 2] < $minedits} {continue}
					if {[clock add [lindex $ret4 1] {*}$age] > [clock seconds]} {continue}
					lappend worklist [list $byteoffset $byteoffset2 [lindex $ret4 0] $number]
				}
			}
		}
		if $bug {
			puts bug:$title
			puts ...
			continue
		}
		if [catch {set worklist2 [lrange $worklist 0 [expr {$topsections-$minsections-1}]]}] {
			puts $title:minsections:$minsections
		}
		set worklist $worklist2
		if {[llength $worklist]} {
			set output {}
			foreach item $worklist {
				dict lappend output [expanddest $dest [lindex $item 2]] [string range $ret2 {*}[lrange $item 0 1]]
			}
			foreach item [lreverse $worklist] {
				set ret2 [string replace $ret2 {*}[lrange $item 0 1]]
			}
			puts $title:[llength $worklist]:$worklist
			#puts age:$age|dest:$dest|minedits:$minedits|minsections:$minsections|header:$header; ##
			set error false
			foreach {dest -} $output {
				if {![string equal -length [string length $title] $title [string map {_ { }} $dest]] && $title ni {}} {
					puts diff:$title:$dest
					set error true
				}
				if {$title eq $dest} {
					puts template2:$title
					set error true
				}
			}
			if $error {
				puts ...
				continue
			}
			puts [set ret6 [edit $title "Archiviere [llength $worklist] [
				expr {[llength $worklist]==1?{Abschnitt}:{Abschnitte}}
			] in [dict size $output] [
				expr {[dict size $output]==1?{Archiv}:{Archive}}
			]" $ret2]]
			if {[dict exists $ret6 error code] && [dict get $ret6 error code] eq {protectedpage}} {
				puts ...
				continue
			}
			foreach {dest sections} $output {
				puts [llength $sections]:$dest
				set ret5 [edit $dest "Archiviere [llength $sections] [expr {[llength $sections]==1?{Abschnitt}:{Abschnitte}}] von \[\[$title\]\]" {}\
				 / appendtext \n[join $sections {}] / nocreate true]
				if {[dict exists $ret5 error code] && [dict get $ret5 error code] eq {missingtitle}} {
						puts [edit $dest "Archiviere [llength $sections] [expr {[llength $sections]==1?{Abschnitt}:{Abschnitte}}] von \[\[$title\]\]"\
						 "$header\n[join $sections {}]"]]
				} else {
					puts $ret5
				}
			}
			puts ...
		}
	}
}} {*}$embeddedin / eititle Vorlage:Autoarchiv
