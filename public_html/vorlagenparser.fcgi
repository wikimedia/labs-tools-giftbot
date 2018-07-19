#!/data/project/shared/tcl/bin/tclsh8.7

# Copyright 2016, 2018 Giftpflanze

# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.

lappend auto_path ../lib

package require Fcgi
package require ncgi
package require wikitext
package require csv

cd ..
set tcl_interactive 1
source api.tcl
source dewiki.tcl
cd public_html

set token [login [set wiki $dewiki]]
set parser [wikitext::parser_critcl]

proc ptemplates {title text ast} {
	global parser template dict parameters t
	set list [lassign $ast type a b]
	if {$type eq {template} && [string toupper [string map {Vorlage: {} Template: {}} [string toupper [string trim [string range $text {*}[lrange [lindex $list 0] 1 2]]] 0 0]] 0 0] eq $template} {
		incr t
		foreach item [lrange $ast 3 end] {
			lassign $item type a b
			if {$type eq {parameter}} {
				set parameter [string trim [string range $text $a $b]]
			} elseif {$type eq {value}} {
				if ![exists parameter] {
					set parameter [incr p]
				}
				dict set parameters $parameter {}
				dict set dict $title $t $parameter [string trim [string range $text $a $b]]
				unset parameter
			}
		}
	}
	foreach item $list {
		ptemplates $title $text $item
	}
	return
}

while {[FCGI_Accept] >= 0} {
	if [catch {
		ncgi::reset
		ncgi::input
		ncgi::setDefaultValue template {}
		ncgi::setDefaultValue namespace 0
		ncgi::importAll template namespace
		set template [string toupper [string map {_ { }} $template] 0 0]
		ncgi::header text/csv Content-Disposition "attachment; filename=\"$template.csv\""

		lassign {} titles parameters list dict
		if {$template ne {}} {
			cont {ret {
				if [dict exists [get $ret] query pages] {
					dict for {- rdict} [get $ret query pages] {
						set t 0
						ptemplates [dict get $rdict title] [set text [dict get [lindex [dict get $rdict revisions] 0] *]] [$parser parset $text]
					}
				}
			}} {*}$query / prop revisions / rvprop content / generator embeddedin / geititle Vorlage:$template / geinamespace $namespace
		}

		set parameters [dict keys $parameters]
		lappend list [list $template [clock format [clock seconds] -locale de -timezone Europe/Berlin]]
		lappend list [list title # {*}$parameters]
		foreach {title embeds} $dict {
			foreach {t embed} $embeds {
			set line [list $title $t]
				foreach parameter $parameters {
					if [dict exists $embed $parameter] {
						lappend line [dict get $embed $parameter]
					} else {
						lappend line {}
					}
				}
				lappend list $line
			}
		}
		puts [csv::joinlist $list]
	}] {
		puts $errorInfo
	}
}
