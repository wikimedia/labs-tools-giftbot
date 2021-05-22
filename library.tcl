# Tool Labs mysql library

# Copyright 2010, 2012, 2013, 2014, 2017 Giftpflanze

# This file is part of the MediaWiki Tcl Bot Framework.

# The MediaWiki Tcl Bot Framework is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

package require inifile
package require mysqltcl

set dbuser [string trim [ini::value [set ini [ini::open $env(HOME)/replica.my.cnf r]] client user] '][ini::close $ini][unset ini]

proc get-db {server {db {}}} {
	mysqlconnect -reconnect 1 -host $server.web.db.svc.wikimedia.cloud -db [expr {[llength $db]?$db:"${server}_p"}]
}
