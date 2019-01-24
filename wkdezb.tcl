#!/data/project/shared/tcl/bin/tclsh8.7

source api.tcl
source dewiki.tcl

set token [login [set wiki $dewiki]]
set page Vorlage:Wechselkursdaten/EZB

curl::transfer -url https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html -bodyvar body

set text [content [post $dewiki {*}$get / titles $page]]

regsub {(?n)(\|STAND=).*} $text [format {\1%s} [clock format [clock seconds] -format %Y-%m-%d -timezone Europe/Berlin]] text

foreach w [dict values [regexp -all -inline {<td id="(.*?)"} $body]] k [dict values [regexp -all -inline {<span class="rate">(.*?)<} $body]] {
	regsub [format {(?n)(\|%s = ).*} $w] $text [format {\1%s} $k] text
}

edit $page {Bot: Aktualisierung} $text / minor
