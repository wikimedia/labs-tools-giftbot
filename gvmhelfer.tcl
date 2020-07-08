#!/data/project/shared/tcl/bin/tclsh8.7

# gvmhelfer.tcl

# Replace no longer working GVMBot functions

# Copyright 2020 Giftpflanze

# gvmhelfer is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

package require struct::set

source api.tcl
source dewiki.tcl
source irc.tcl

proc get-sections {} {
	global dewiki get
	lmap section [lmap {- section} [regexp -all -inline {(?n)^==(.*)==[ \t]*$} [content [post $dewiki {*}$get / titles Wikipedia:Vandalismusmeldung]]] {string trim $section}] {
		expr {[string match *(erl.) $section]?[continue]:$section}
	}
}

set self GVMBotHelfer
set watchlist [get-sections]
set fnh [register-fn [set channel wikipedia-de-rc] {args {}}]

register-rc de.wikipedia {{- - title args} {
	global watchlist fnh channel
	lassign [struct::set intersect3 $watchlist [set watchlist [get-sections]]] - removed added
	foreach item $removed {
		puts $fnh "PRIVMSG #$channel :erledigt: $item"
	}
	foreach item $added {
		puts $fnh "PRIVMSG #$channel :neuer Abschnitt: $item"
	}
}}

vwait exit
