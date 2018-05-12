#!/data/project/shared/tcl/bin/tclsh8.7

# autoarchiv.tcl

# ArchivBot replacement (dewikisource)

# Copyright 2011, 2012 Giftpflanze

# autoarchiv.tcl is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

package require cmdline
package require math::roman

source api.tcl
source dewikisource.tcl

set token [login [set wiki $dewikisource]]

dict for {key value} [cmdline::getKnownOptions argv {{daytime.arg morgens {morgens|mittags}}}] {
	if {$value ne {}} {
		set $key $value
	}
}


proc parsesection {section} {
	foreach ts [regexp -all -inline {[0-9]{2}:[0-9]{2}, [0-9]{1,2}\. (?:(?:Jan|Feb|Mär|Apr|Jun|Jul|Aug|Sep|Okt|Nov|Dez)\.*|Mai) [0-9]{4} \(CES{0,1}T\)} $section] {
		if [catch {set ts [clock scan $ts -format {%H:%M, %d. %b. %Y (%Z)} -timezone Europe/Berlin -locale de]}] {
			if [catch {set ts [clock scan $ts -format {%H:%M, %d. %b %Y (%Z)} -timezone Europe/Berlin -locale de]}] {
				puts error:ts:$ts
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
	global title
	set dest [string map [list \
		' {} \
		((Lemma)) $title \
		((FULLPAGENAME)) $title \
		((Woche)) [string trimleft [clock format $ts -timezone Europe/Berlin -locale de -format %V] 0]
	] $dest]
	foreach {pattern add divide mod1 mod2} {
			((Quartal)) 2 3 none trim
			((Quartal:##)) 2 3 fill trim
			((Quartal:i)) 2 3 roman tolower
			((Quartal:I)) 2 3 roman toupper
			((Halbjahr)) 5 6  none trim
			((Halbjahr:##)) 5 6 fill trim
			((Halbjahr:i)) 5 6 roman tolower
			((Halbjahr:I)) 5 6 roman toupper
			((Semester:I)) 5 6 roman toupper
			qqq 2 3 roman toupper
			qq 2 3 fill trim
			QQQ 2 3 roman toupper
		} {
		set number [expr {([string trimleft [clock format $ts -timezone Europe/Berlin -locale de -format %m] 0] + $add) / $divide}]
		switch $mod1 {
			fill {set number [format %02u $number]}
			roman {set number [math::roman::toroman $number]}
		}
		set dest [string map [list $pattern [string $mod2 $number]] $dest]
	}
	foreach {pattern replace mod} {
			((Tag)) %e trim
			((Tag:##)) %d trim
			((Tag:kurz)) %a tolower
			((Tag:Kurz)) %a totitle
			((Tag:KURZ)) %a toupper
			((Tag:lang)) %A tolower
			((Tag:Lang)) %A totitle
			((Tag:LANG)) %A toupper
			((Woche:##)) %V trim
			((Monat)) %N trim
			((Monat:##)) %m trim
			((Monat:kurz)) %b tolower
			((Monat:Kurz)) %b trim
			((Monat:KURZ)) %b toupper
			((Monat:lang)) %B tolower
			((Monat:Lang)) %B trim
			((Monat:LANG)) %B toupper
			((Jahr)) %Y trim
			((Jahr:##)) %y trim
			yyyy %Y trim
			yy %y trim
			MMMM %B trim
			MMM %b trim
			MM %m trim
			mmmm %B trim
			mmm %b trim
		} {
		set dest [string map [list $pattern [string $mod [clock format $ts -timezone Europe/Berlin -locale de -format $replace]]] $dest]
	}
	return $dest
}

cont {ret1 {
	foreach item [embeddedin $ret1] {
		#if $tcl_interactive { set title Diskussion:Tutanchamun; set ret2 [content [post $wiki {*}$get / titles $title / rvstartid 112884313]] }
		set ret2 [content [post $wiki {*}$get / titles [set title [dict get $item title]]]]
		#blacklist
		#if {$title in {}} {
		#	continue
		#}
		if ![regexp {{{\n*(Vorlage:)*[Aa]utoarchiv[ \n]*\|[^\{\}]*(?:{{[^\{\}]*}}[^\{\}]*)*}}} $ret2 template] {
			puts error:template:$title
			puts ...
			continue
		}
		regsub -all {<!--.*?-->} $template {} template
		regexp {Alter *= *([^|\}\n]*?)} $template -> age
		if ![regexp {Ziel *= *([^|\}\n]*?)} $template -> dest] {
			puts error:nodest:$title
			puts ...
			continue
		}
		set dest [string trim $dest]
		set minedits 2
		regexp {Mindestbeiträge *= *([^|\}\n]*?)} $template -> minedits
		set minsections 0
		regexp {Mindestabschnitte *= *([^|\}\n]*?)} $template -> minsections
		set frequency ständig
		regexp {Frequenz *= *([^|\}\n]*?)} $template -> frequency
		set mode Alter
		regexp {Modus *= *([^|\}\n]*?)} $template -> mode
		set alter false
		set erledigt false
		set minor Nein
		regexp {Klein *= *([^|\}\n]*?)} $template -> minor
		if [regexp {[Aa]lter} $mode] {
			set alter true
		}
		if [regexp {[Ee]rledigt} $mode] {
			set erledigt true
		}
		set run false
		foreach frequency [lrange [regexp -all -inline {(?:([^,].*?), *)*([^,].*?)} $frequency] 1 end] {
			set frequency [string trim [string tolower $frequency]]
			if {$frequency eq {}} {
				continue
			}
			set dt {morgens}
			regexp {([^:]*)(?::(.*)|$)} $frequency -> frequency dt
			if {$dt eq {}} {
				set dt morgens
			}
			if {$frequency eq {morgens}} {
				set frequency ständig
				set dt morgens
			}
			if {$frequency eq {mittags}} {
				set frequency ständig
				set dt mittags
			}
			if {$frequency eq {ständig}} {
				set dt ständig
			}
			if {$dt ne $daytime && $dt ne {ständig}} {
				continue
			}
			set yesterday [clock add [clock seconds]]
			#-1 day
			switch -nocase $frequency {
				nie {
					set run false
				}
				täglich {
					set run true
				}
				'ständig' {
					set run true
				}
				ständig {
					set run true
				}
				dauernd {
					set run true
				}
				halbmonatlich {
					if {[clock format $yesterday -format %d -timezone Europe/Berlin] in {1 15}} {
						set run true
					}
				}
				monatlich {
					if {[clock format $yesterday -format %d -timezone Europe/Berlin] == 1} {
						set run true
					}
				}
				vierteljährlich {
					if {[clock format $yesterday -format %d%m -timezone Europe/Berlin] in {0101 0104 0107 0110}} {
						set run true
					}
				}
				halbjährlich {
					if {[clock format $yesterday -format %d%m -timezone Europe/Berlin] in {0101 0107}} {
						set run true
					}
				}
				jährlich {
					if {[clock format $yesterday -format %d%m -timezone Europe/Berlin] eq {0101}} {
						set run true
					}
				}
				default {
					if [catch {if {[clock format $yesterday -format %u -timezone Europe/Berlin] ==\
					 [dict get {montags 1 dienstags 2 mittwochs 3 donnerstags 4 freitags 5 samstags 6 sonntags 7 wöchentlich 1} $frequency]} {
						set run true
					}}] {
						puts error:frequency:$title:$frequency
						puts ...
						#set run true
					}
				}
			}
		}
		if !$run {
			continue
		}
		set topsections 0
		set offset 0
		set worklist {}
		set bug false
		#if $tcl_interactive { set ret3 [post $wiki {*}$format / action parse / prop sections / oldid 112884313] }
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
					#calculate end of single "toplevel" section
					foreach item3 [lrange $sections $offset end] {
						if {[dict get $item3 level] > 2 || [dict get $item3 byteoffset] eq {null}} {
							incr offset2
						} else break
					}
					set ret4 [parsesection [set section [string range $ret2 $byteoffset [set byteoffset2 [
						expr {([lindex $sections $offset2] ne {} && [dict get [lindex $sections $offset2] byteoffset] ne {null})?
						 [dict get [lindex $sections $offset2] byteoffset]-1:{end}}
					]]]]]
					if {[lindex $ret4 2] < $minedits} {
						continue
					}
					if $alter {
						case [catch {
							if {!([lindex $ret4 1] < ([catch {expr {$age}}]?[clock add [clock seconds] -[string map {h {}} $age] hours]:[clock add [clock seconds]\
							 -[expr {$age}] days]))} {
							#-1 day; $age+1
								continue
							}
						}] 1 {
							puts error-h:$title
							continue
						} 4 {
							continue
						}
					}
					if $erledigt {
						if ![regexp {{{erledigt(}}|\|)} $section] {
							continue
						}
					}
					if [regexp {{{(Vorlage:)*[Nn]icht archivieren(}}|\|)} $section] {
						continue
					}
					lappend worklist [list $byteoffset $byteoffset2 [lindex $ret4 0] $number]
				}
			}
		}
		#if $tcl_interactive { return }
		#silently ignore
		if $bug {
			#puts bug:$title
			#puts ...
			continue
		}
		if [catch {set worklist2 [lrange $worklist 0 [expr {$topsections-$minsections-1}]]}] {
			puts error:minsections:$title:$minsections
		}
		set worklist $worklist2
		if {[llength $worklist]} {
			set output {}
			puts [llength $worklist]:$title:$worklist
			if [catch {
			foreach item $worklist {
				dict lappend output [expanddest $dest [lindex $item 2]] [string range $ret2 {*}[lrange $item 0 1]]
			}}] {
				puts error-expanddest
				puts ...
				continue
			}
			foreach item [lreverse $worklist] {
				set ret2 [string replace $ret2 {*}[lrange $item 0 1]]
			}
			#puts age:$age|dest:$dest|minedits:$minedits|minsections:$minsections|frequency:$frequency|mode:$mode|alter:$alter|erledigt:$erledigt|minor:$minor
			set error false
			foreach {dest -} $output {
				#exeptions to same basepage rule
				if {![string equal -length [string length $title] $title [string map {_ { }} $dest]] && $title ni {Benutzer:THEbotIT/Logs/GLStatus}} {
					puts error:titlediff:$title:$dest
					set error true
				}
				if {$title eq $dest} {
					puts error:dest=title:$title
					set error true
				}
			}
			if $error {
				puts ...
				continue
			}
			puts [set ret6 [edit $title "Archiviere [llength $worklist] [
				expr {[llength $worklist]==1?{Abschnitt}:{Abschnitte}}
			] [
				expr {[dict size $output]==1?"nach \[\[[lindex $output 0]\]\]":"in [dict size $output] Archive"}
			]" $ret2 {*}[expr {$minor ne {Nein}?{/ minor}:{}}]]]
			if {[dict exists $ret6 error code] && [dict get $ret6 error code] in {editconflict protectedpage}} {
				puts ...
				continue
			}
			### {{erledigt}} rausregexen
			foreach {dest sections} $output {
				puts [llength $sections]:$dest
				set ret5 [edit $dest "Archiviere [llength $sections] [expr {[llength $sections]==1?{Abschnitt}:{Abschnitte}}] von \[\[$title\]\]" {}\
				 / appendtext \n[join $sections {}] / nocreate true {*}[expr {$minor ne {Nein}?{/ minor}:{}}]]
				if {[dict exists $ret5 error code] && [dict get $ret5 error code] eq {missingtitle}} {
						puts [edit $dest "Archiviere [llength $sections] [expr {[llength $sections]==1?{Abschnitt}:{Abschnitte}}] von \[\[$title\]\]"\
						 "{{Archiv|$title}}\n[join $sections {}]" {*}[expr {$minor ne {Nein}?{/ minor}:{}}]]]
				} else {
					puts $ret5
				}
			}
			puts ...
		}
	}
}} {*}$embeddedin / eititle Vorlage:Autoarchiv
