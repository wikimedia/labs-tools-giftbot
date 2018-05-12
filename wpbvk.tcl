#!/data/project/shared/tcl/bin/tclsh8.7

# wpbvkbot – de:WP:WPBVK update bot

# Make daily summary of Special:Prefixindex/WP:WPBVK/Stoffsammlung/ and
# destination pages

# Copyright 2011, 2018 Giftpflanze

# wpbvkbot is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl

set ret [post $dewiki {*}$allpages / apprefix WPBVK/Stoffsammlung/ / apnamespace 4]

foreach item [allpages $ret] {
	dict with item {
		append text [format {* [[%s]]: [[%s]]} $title [lindex [regexp -inline {Wikipedia:WPBVK/Stoffsammlung/(.*)} $title] 1]]\n
	}
}

set token [login [set wiki $dewiki]]
puts [edit Wikipedia:WPBVK/Stoffsammlung {Bot: Aktualisierung} $text / minor true]
