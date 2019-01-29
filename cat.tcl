# cat.tcl Library

# Recursive Category traversal

# Copyright 2010, 2014 Giftpflanze

# This file is part of the MediaWiki Tcl Bot Framework.

# The MediaWiki Tcl Bot Framework is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

#set wiki
proc cat {cat namespace {exclude {}}} {
	global catmem
	set return {}
	cont {ret {
		foreach item [catmem $ret] {
			dict with item {
				if {$ns == 14} {
					if {$title ni $exclude} {
						lappend return {*}[cat $title $namespace $exclude]
					}
				}
				if {$ns == $namespace} {
					lappend return $title
				}
			}
		}
	}} {*}$catmem / cmtitle $cat / cmnamespace $namespace|14
	return $return
}

proc cat-db {db cat namespace {recursive 1}} {
	set return {}
	foreach {ns title} [mysqlsel $db "select page_namespace, page_title from categorylinks, page where cl_from = page_id and page_namespace in (14, [mysqlescape $namespace]) and cl_to =\
	 '[mysqlescape [string map {{ } _} $cat]]'" -flatlist] {
		if {$ns == $namespace} {
			lappend return [string map {_ { }} $title]
		}
		if {$ns == 14 && $recursive} {
			lappend return {*}[cat-db $db $title $namespace $recursive]
		}
	}
	struct::set union [lmap title $return {string map {_ { }} $title}] {}
}

return
