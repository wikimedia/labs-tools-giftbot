#!/data/project/shared/tcl/bin/tclsh8.7

# wkdezb.tcl

# Update ECB exchange rates

# Copyright 2019 Giftpflanze

# wkdezb.tcl is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

source api.tcl
source alswiki.tcl

set token [login [set wiki $alswiki]]
set page Vorlage:Wechselkursdaten/EZB

curl::transfer -url https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html -bodyvar body

set text [content [post $wiki {*}$get / titles $page]]

regsub {(?n)(\|STAND=).*} $text [format {\1%s} [clock format [clock seconds] -format %Y-%m-%d -timezone Europe/Berlin]] text

foreach w [dict values [regexp -all -inline {<td id="(.*?)"} $body]] k [dict values [regexp -all -inline {<span class="rate">(.*?)<} $body]] {
	regsub [format {(?n)(\|%s = ).*} $w] $text [format {\1%s} $k] text
}

puts [edit $page {Bötli: Aktualisierung} $text / minor]
