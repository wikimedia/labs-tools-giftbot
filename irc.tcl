# irc.tcl Library

# Accessing Wikimedia and Freenode/Libera Chat IRC

# Copyright 2010, 2011, 2012, 2014, 2018 Giftpflanze

# This file is part of the MediaWiki Tcl Bot Framework.

# The MediaWiki Tcl Bot Framework is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

# RC channels have the format #<lang>.<wikifamiliy>
# Call [vwait exit] to start listening

proc handler {handle callback callback2} {
	global connectivity
	if {[gets $handle line] < 0} {
		puts {broken socket}
		exit 1
	}
	if [info exists connectivity($handle)] {
		after cancel $connectivity($handle)
	}
	set connectivity($handle) [after 300000 {
		puts {inactivity}
		exit 1
	}]
	set list [split $line]
	if {[lindex $list 0] eq {PING}} {
		puts $handle "PONG [info hostname] [lindex $list 1]"
	}
	if {[lindex $list 0] eq {ERROR}} {
		puts [lrange $list 1 end]
		exit 1
	}
	if {[lindex $list 1] eq {PRIVMSG}} {
		apply $callback $line $callback2
	}
}

proc register-irc {nick server password channels callback callback2} {
	global tcl_platform env
	set user [set tool [string map {tools. {}} $tcl_platform(user)]]-[set jobname $env(JOB_NAME)]-[set jobid $env(JOB_ID)]
	if ![llength $nick] {
		set nick $user
	}

	set handle [socket $server 6667]
	fconfigure $handle -buffering line -translation crlf

	if [llength $password] {
		puts $handle "PASS $password"
	}
	puts $handle "NICK $nick"
	puts $handle "USER $user 0 * :$user"
	foreach channel $channels {
		puts $handle "JOIN #$channel"
	}

	fileevent $handle r [list handler $handle $callback $callback2]
	return $handle
}

proc register-rc {channels callback} {
	register-irc {} irc.wikimedia.org {} $channels {{line callback} {
		if ![regexp {:[^ ]+ PRIVMSG #([^ ]+) :(.*)} $line -> channel msg] return
		if ![regexp {14\[\[07(.*)14\]\]4 (.*)10 02(.*) 5\* 03(.*) 5\* \(??\+?([^)]*)?\)? 10(.*)?} $msg -> title action url user diff comment] return
		apply $callback $channel $msg $title $action $url $user $diff $comment
	}} $callback
}

proc register-lc {channels callback} {
	global self liberapwd
	register-irc $self irc.libera.chat $liberapwd $channels {{line callback} {
		if ![regexp {:([^ ]+)![^ ]+@([^ ]+) PRIVMSG ([^ ]+) :(.*)} $line -> nick host recipient msg] {
			puts parse-error:$line
		} else {
			apply $callback $nick $host $recipient $msg
		}
	}} $callback
}

proc bgerror {msg} {
	global fnh errorInfo
	puts stderr $msg
	puts stderr $errorInfo
	catch {puts $fnh "QUIT :[lindex [split $errorInfo \n] 0]"}
	exit 1
}
