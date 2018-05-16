# curl.tcl Library

# Accessing TclCurl – Low-level Access to the MediaWiki API

# Copyright 2010, 2011, 2012, 2014, 2017 Giftpflanze

# This file is part of the MediaWiki Tcl Bot Framework.

# The MediaWiki Tcl Bot Framework is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

package require TclCurl
package require oauth 1.0.1

# Test if variable exists in caller scope (standard)
# Use #0 for level to test in the global scope
proc exists {var {level 1}} {
	expr {$var in [uplevel $level {info vars}]}
}

# Put debug information if debug is set (exists)
proc debug {code} {
	if [exists debug #0] {
		uplevel $code
	}
}

# API call wrapper
# call: post $handle / param1 value1 / param2 value2 ...
proc post {handle args} {
	global headers access_token access_secret consumer_token consumer_secret login_oauth
	oauth::config -accesstoken $access_token -accesstokensecret $access_secret -consumerkey $consumer_token -consumersecret $consumer_secret
	foreach {/ name value} $args {
		lappend pairs "[curl::escape $name]=[curl::escape $value]"
	}
	do {
		array unset headers
		$handle configure -postfields [set string [join $pairs &]] -bodyvar body -httpheader [list [join [oauth::header $login_oauth($handle) $string] {: }]]
		$handle perform
	} until {
		!([dict exists [get $body] error code] &&
		[get $body error code] eq {mwoauth-invalid-authorization} &&
		[string match {*Nonce already used*} [get $body error info]]) &&
		[true {debug {puts $args; puts [get $body]}}] &&
		[catch {
			after [expr {[set replag $headers(Retry-After)]*1000}]
			if ![exists quiet #0] {
				puts "replag: ${replag}s"
			}
		}] &&
		([lindex $headers(http) 1] eq 200 || ![true {
			if ![exists quiet #0] {
				puts $headers(http)
			}
			after 10000
		}])
	}
	return [encoding convertfrom [encoding convertfrom [encoding convertto $body]]]
}

# Get API handle
proc get-handle {lang wiki {scheme https}} {
	global self email format login_oauth
	#global password login_old login
	[set handle [curl::init]] configure \
	-useragent "$self@$lang.$wiki <$email> – MediaWiki Tcl Bot Framework 1.1 (git [string range [exec git rev-parse HEAD] 0 6])" \
	-encoding all \
	-cookiefile cookies \
	-url $scheme://$lang.$wiki.org/w/api.php \
	-sslverifypeer 0 \
	-headervar headers
	#set login_old($handle) [list {*}$format / action login / lgname $self / lgpassword $password]
	#set login($handle) [list {*}$format / action clientlogin / username $self / password $password / loginreturnurl $scheme://$lang.$wiki.org/]
	set login_oauth($handle) $scheme://$lang.$wiki.org/w/api.php
	return $handle
}

return
