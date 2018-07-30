#!/data/project/shared/tcl/bin/tclsh8.7

# Dereferrer

# Copyright 2018 Giftpflanze

# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.

package require Fcgi
package require ncgi
package require htmlgen
namespace import htmlgen::*

source ../library.tcl

set dewiki [get-db dewiki]

while {[FCGI_Accept] >= 0} {
	if [catch {
		ncgi::reset
		ncgi::input
		ncgi::import url
		if [mysqlsel $dewiki "
			select el_to from externallinks where
			el_to = '//[set * [mysqlescape $env(HTTP_HOST)$env(SCRIPT_NAME)?url=[string map {= %3D & %26 # %23 % %25} $url]]]' or
			el_to = 'http://${*}' or
			el_to = 'https://${*}'
		"] {
			puts {HTTP/1.1 307 Temporary Redirect}
			ncgi::header {text/html; charset=utf-8} Location $url
		} else {
			puts {HTTP/1.1 403 Forbidden}
			ncgi::header {text/html; charset=utf-8}
			pre - [esc $url] kommt in der deutschsprachigen Wikipedia nicht vor.
		}
	}] {
		pre - $errorInfo
	}
}
