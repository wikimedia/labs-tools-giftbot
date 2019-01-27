#!/data/project/shared/tcl/bin/tclsh8.7

# kurzeartikel.tcl

# Find short articles with exclusion lists

# Copyright 2013, 2019 Giftpflanze
# Original script by Guandalug (especially the sql)

# kurzeartikel.tcl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.

package require struct::set

source api.tcl
source dewiki.tcl
source library.tcl
source cat.tcl

set page {Wikipedia:Kurze Artikel}
set intro $page/Intro
set exceptions $page/Ausnahmen

set dewiki_p [get-db dewiki]
set token [login [set wiki $dewiki]]

set text1 [content [post $dewiki {*}$get / titles $intro]]
set cats [lmap cat [struct::set union {*}[lmap {-> cat} [regexp -all -inline {\[\[:(Kategorie:.*?)\|} $text1] {list $cat {*}[cat $cat 14]}]] {string map {Kategorie: {}} $cat}]

set text2 [content [post $dewiki {*}$get / titles $exceptions]]
set exceptions [lmap {-> exception} [regexp -all -inline {\[\[(.*?)\]\]} $text2] {set exception}]

set res [mysqlsel $dewiki_p "select page_title, page_len from page where page_is_redirect=false and page_namespace=0 and not exists (select 1 from categorylinks where cl_from=page.page_id and\
 cl_to in ([join [lmap cat $cats {set cat '[mysqlescape [string map {{ } _} $cat]]'}] {, }])) [expr {[llength $exceptions]?"and page_title not in ([join [lmap exception $exceptions {set\
 exception '[mysqlescape [string map {{ } _} $exception]]'}] {, }])":{}}] order by page_len asc, page_title asc limit 1000" -flatlist]

puts [edit $page {Bot: Seite aktualisiert} "{{$intro}}\nLetztes Update: [clock format [clock seconds] -format {%d.%m.%Y %H:%M:%S} -timezone Europe/Berlin]\n[join [lmap {title length} $res {set\
 line "# \[\[[string map {_ { }} $title]\]\] ($length Byte)"}] \n]\n{{Navigationsleiste Wartungslisten}}"]
