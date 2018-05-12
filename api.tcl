# api.tcl Library

# Providing convenience procs for the MediaWiki API

# Copyright 2010, 2011, 2012, 2014, 2017 Giftpflanze

# This file is part of the MediaWiki Tcl Bot Framework.

# The MediaWiki Tcl Bot Framework is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

if !$tcl_interactive {
	puts ----
	puts [clock format [clock seconds] -format %c -locale de]
}

package require control
namespace import control::do

source curl.tcl
source json.tcl
source params.tcl

proc login {handle} {
	return "/ token [get-token $handle]"
}

proc get-token {handle} {
	global query
	get [post $handle {*}$query / meta tokens] query tokens csrftoken
}

proc true {script} {
	uplevel $script
	return true
}

set bot true

# automated editing, retries if logged out
# set wiki
# set token [login $wiki]
proc edit {title summary text args} {
	global wiki token put bot headers
	do {
		set ret [get [post {*}$wiki {*}$token {*}$put / title $title / summary $summary / text $text {*}[expr $bot?{/ bot true}:{}] {*}$args]]
	} while {
		[dict exists $ret error code] &&
		[dict get $ret error code] in {badtoken unknownerror assertuserfailed}
	}
	#pass certain error conditions
	if {[dict exists $ret error code] && [dict get $ret error code] in {editconflict nosuchsection protectedpage missingtitle undofailure nosuchrevid articleexists}} {
		return $ret
	}
	if {![dict exists $ret edit result] || [dict get $ret edit result] ne {Success}} {
		parray headers
		error $ret
	}
	if ![dict exists $ret edit nochange] {
		after 12000
	}
	return $ret
}

# gets all api continuations and executes a script for each of them
# set wiki
proc cont {lambda args} {
	global wiki
	upvar [lindex $lambda 0] ret
	lassign {} cont cont2
	do {
		set ret [post $wiki {*}$args / continue $cont / {*}$cont2]
		uplevel [lindex $lambda 1]
	} until {[catch {
		set cont [get $ret continue continue]
		set cont2 [lrange [get $ret continue] 0 1]
	}]}
}

# scan api timestamp
proc scan-ts {ts} {
	clock scan $ts -format %Y-%m-%dT%H:%M:%SZ
}

return
