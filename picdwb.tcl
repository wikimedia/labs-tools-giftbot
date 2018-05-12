#!/data/project/shared/tcl/bin/tclsh8.7

# picdwb

# Count pages in category:WP:Defekte Weblinks/Bot/alle

# Copyright 2012 Giftpflanze

# picdwb is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source dewiki.tcl

set token [login [set wiki $dewiki]]

puts [edit Benutzer:GiftBot/Testseite {Bot: Test} {} / appendtext "\n[clock format [clock seconds] -format {%x %X} -locale de -timezone Europe/Berlin]:\
 {{ers:PAGESINCAT:Wikipedia:Defekte Weblinks/Bot}}<br>"]
