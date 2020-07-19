#!/data/project/shared/tcl/bin/tclsh8.7

# unreviewedmoves.tcl

# List unreviewed pages that have been moved by autoreviewers from the user
# namespace to the article namespace

# Copyright 2020 Giftpflanze

# unreviewedmoves.tcl is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.

source api.tcl
source dewiki.tcl
source library.tcl

set dewiki_p [get-db dewiki]
set token [login [set wiki $dewiki]]

set output "Diese Seite listet ungesichtete Artikel auf, die von einem passiven Sichter vom Benutzernamensraum in den Artikelnamensraum verschoben worden sind.\n\n"

foreach {title params} [mysqlsel $dewiki_p {
	select page_title, log_params
	from page left join flaggedpages on page_id = fp_page_id
	join logging on page_id = log_page
	join actor on log_actor = actor_id
	join user_groups on actor_user = ug_user
	where fp_reviewed is null
	and page_namespace = 0
	and log_namespace = 2
	and log_type = "move"
	and ug_group = "autoreview"
} -flatlist] {
	regexp {a:3:\{s:9:"4::target";s:\d+?:"(.*?)";} $params -> target
	if ![regexp ^Benutzer $target] {
		append output "* \[\[[string map {_ { }} $title]\]\]\n"
	}
}

puts [edit {Wikipedia:Gesichtete Versionen/Ungesichtete Verschiebungen} {Bot: aktualisiere Seite} $output]
