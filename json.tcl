# json.tcl Library

# Parsing json-formatted API return data

# Copyright 2010, 2011, 2014, 2016 Giftpflanze

# This file is part of the MediaWiki Tcl Bot Framework.

# The MediaWiki Tcl Bot Framework is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

package require json

set format {/ format json / maxlag 5 / utf8 true}

proc get {json args} {
	dict get [json::json2dict $json] {*}$args
}

# prop info
# prop revisions

proc page {json args} {
	dict get [lindex [get $json query pages] 1] {*}$args
}

proc revision {json args} {
	dict get [lindex [page $json revisions] 0] {*}$args
}

# rvprop content|…

proc content {json} {
	dict get [revision $json] *
}

# list logevents

proc logevents {json args} {
	dict get [lindex [get $json query logevents] 0] {*}$args
}

# list categorymembers

proc catmem {json} {
	get $json query categorymembers
}

# list allpages

proc allpages {json} {
	get $json query allpages
}

# list usercontribs

proc lastcontrib {json} {
	if [dict exists [lindex [get $json query usercontribs] 0] timestamp] {
		dict get [lindex [get $json query usercontribs] 0] timestamp
	}
}

# list embeddedin

proc embeddedin {json} {
	get $json query embeddedin
}

return
