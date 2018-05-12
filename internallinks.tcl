#!/data/project/shared/tcl/bin/tclsh8.7

# internallinks.tcl

# Find internal links that link to anchors that don't exist
# See https://de.wikipedia.org/wiki/Wikipedia:Bots/Anfragen/Archiv/2011-2#interne_Links

# Copyright 2012, 2013, 2014 Giftpflanze

# internallinks.tcl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.

package require uri::urn
package require htmlparse
package require tdom
package require Trf

source library.tcl

proc quote {string} {
	set string [string trim $string]
	set string [string map {{ } _} $string]
	set string [htmlparse::mapEscapes $string]
	set string [uri::urn::quote $string]
	set string [string map {% . ( .28 ) .29 , .2C} $string]
}

proc unquote {string} {
	set string [string map {_ { } . %} $string]
	set string [string map {%00 .00 %01 .01 %02 .02 %03 .03 %04 .04 %05 .05 %06 .06 %07 .07 %08 .08 %09 .09 %0a .0a %0b .0b %0c .0c %0d .0d %0e .0e %0f .0f %10 .10 %11 .11 %12 .12 %13 .13\
	 %14 .14 %15 .15 %16 .16 %17 .17 %18 .18 %19 .19 %1a .1a %1b .1b %1c .1c %1d .1d %1e .1e %1f .1f %C2%A0 .C2.A0} $string]
	set string [uri::urn::unquote $string]
	set string [string map {% .} $string]
}

proc sanitize {title} {
	set title [string map {_ { }} $title]
	set title [regsub -all _{2,} $title _]
	set title [string trim $title]
	set title [htmlparse::mapEscapes $title]
	set title [subst -nocommands -novariables [regsub {&#(x[0-9A-F]+);} $title {\\\1}]]
}

proc anchors {article} {
	set anchors {}
	foreach {-> anchor} [regexp -all -inline {(?n)^(?:=+) *(.+?) *=+ *(?:<!--.*?-->)*(?:<!--){0,1}$} $article] {
		regsub -all {\[\[(?:Bild|Datei|File):[^\]]*?\]\]} $anchor {} anchor; #file links
		regsub -all {\[\[(?:[^]|]+\|)*([^]]+)\]\]} $anchor {\1} anchor; #subst piped links
		regsub -all {{{lang\|.*?\|(.*)}}} $anchor {\1} anchor; #prettify {{lang|…|…}}
		regsub -all {{{[Pp]olytonisch\|(.*?)}}} $anchor {\1} anchor; #prettify {{polytonisch}}
		regsub -all {{{[^\}]*?}}} $anchor {} anchor; #remove templates
		regsub -all {<.*?/>} $anchor {} anchor; #remove single tags
		regsub -all {<(.*?)(?: .*?)*>(.*?)</\1>} $anchor {\2} anchor; #remove tag pairs
		regsub -all { +} $anchor { } anchor; #multiple spaces
		set anchor [htmlparse::mapEscapes $anchor]; #subst entities
		set anchor [string map {''' {} '' {} _ { }} $anchor]; #remove markup, subst underscores, nbsp
		set anchor [string trim $anchor]
		if {[quote $anchor] in $anchors} {
			set i 1
			while {[quote "${anchor} [incr i]"] in $anchors} {}
			lappend anchors [quote ${anchor}_$i]
		} else {
			lappend anchors [quote $anchor]
		}
	}
	foreach {-> snippet} [regexp -all -inline {{{[Aa]nker *\|([^\}]+?)}}} $article] {
		foreach anchor [split $snippet |] {
			lappend anchors [quote $anchor]
		}
	}
	foreach {-> anchor} [concat\
			[regexp -all -inline {id *?= *?"*([^\n]+?)(?="|/|>)} $article]\
			[regexp -all -inline {\{\{LDLBerlin\|(\d+)} $article]\
			[regexp -all -inline {{{[Cc]ite book\|.+?\|ref=(.+?)}}} $article]\
			[regexp -all -inline {{{Japanischer Charakter *\n* *\|[^\]]*\|name *= *([^|]*?) *\n *\|[^\}]*?}}} $article]\
			[regexp -all -inline {\{\{WP-HB LfD\|(\d+)} $article]\
			[regexp -all -inline {\{\{Denkmalliste1 Tabellenzeile\n\|.*?\|Nummer *= *(.*) *(?:\n|\}\})} $article]\
			[regexp -all -inline {{{Coordinate\|.+?\|name=([^|]+?)(?:}}|\|)} $article]\
			[regexp -all -inline {\{\{Futurama-Episode.+?\| *DT *= *(?:\[\[){0,1}(.+?)(?:\]\]){0,1} *\n} $article]\
			[lmap {-> 1 2} [regexp -all -inline {\{\{Denkmalliste Sachsen Tabellenzeile\n.+?\|Name *= *(.*) *\n\|Adresse *= *(.*) *(?:\n)} $article] {join [list $1 $2] {, }}]] {
		lappend anchors [quote $anchor]
	}
	lappend anchors top toc
}

proc dump {file content} {
	puts [set handle [open $file w]] $content
	close $handle
}

proc readf {varn file} {
	upvar $varn var
	set var [read [set h [open $file]]][close $h]
	return
}

proc tag {tag2 list} {
	global tag
	set tag $tag2
}

proc data {data} {
	global tag title pass errorInfo
	switch $tag {
		{title} {
			set title $data
		}
		{text} {
			if [catch {
			$pass $title $data
			}] {puts $errorInfo}
		}
	}
	set tag {}
}

proc firstpass {title article} {
	#puts firstpass;#
	global sql firstpass_list firstpass
	foreach {-> link} [regexp -all -inline {\[\[(([^][|#]+?)#([^][|]+?))(?=\]\]|\|)} [regsub <!--.*?--> $article {}]] {
		if ![regexp {^([^#]*?)#(.+)$} [sanitize $link] -> dest anchor] {
			continue
		}
		if {$dest eq {}} {
			set dest $title
		}
		if [llength [set dest2 [string map {_ { }} [mysqlsel $sql "select rd_title from redirect, page where page_namespace = 0 and page_title = '[mysqlescape [string map {{ } _}\
		 $dest]]' and rd_from = page_id" -list]]]] {
			set dest $dest2
		}
		regsub {(^Anker:)} $anchor {} anchor
		set anchor [quote $anchor]
		if [regexp ^(fi|Datei|Wikipedia|Kategorie|Vorlage|Hilfe|Portal): $dest] continue
		if [regexp ^(Datei|Kategorie|Wikipedia|Hilfe|Portal|Vorlage|MediaWiki|Modul): $title] continue
		lappend firstpass_list [list [set dest [encoding convertfrom identity [string map {\xA0 { }} [uri::urn::unquote $dest]]]] $anchor $title $link]
		lappend firstpass [list $title $dest $anchor $link]
	}
}

proc secondpass {title article} {
	#puts secondpass;#
	global sql wiki date firstpass secondpass secondpass_list auto
	if [dict exists $firstpass $title] {
		dict for {anchor pages} [dict get $firstpass $title] {
			if {$anchor ni [set anchors [anchors $article]]} {
				#puts "* \[\[$title#[unquote $anchor]\]\]: [join [lmap page [dict keys $pages] {set page \[\[$page\]\]}] {, }]"
				dict for {page origs} $pages {
					foreach orig $origs {
						set revid_source [mysqlsel $sql "select page_latest from page where page_title = '[mysqlescape [string map {{ } _} $page]]' and page_namespace =\
						 0" -list]
						set revid_dest [mysqlsel $sql "select page_latest from page where page_title = '[mysqlescape [string map {{ } _} $title]]' and page_namespace =\
						 0" -list]
						if ![llength $revid_source] {set revid_source NULL}
						if ![llength $revid_dest] {set revid_dest NULL}
						if [catch {mysqlexec $sql [set dbg "insert into ${wiki}_$date values ('[mysqlescape $page]', '[mysqlescape $orig]', $revid_source, $revid_dest,\
						 [llength [dict keys $pages]])"]}] {
							#puts stderr $dbg
						}
						if {$revid_dest eq {NULL}} {
							#puts stderr $dbg
						}
						lappend secondpass_list [list $page $title $anchor $orig]
					}
				}
				dict set container $anchor $pages
			}
		}
		if {{container} in [info vars]} {
			dict set secondpass $title $container
		}
	}
}

proc sort {list} {
	set prev {}
	foreach item [lsort -index 0 $list] {
		foreach {a b c d} $item {
			if {$a ne $prev} {
				if {$prev ne {}} {
					dict for {b2 cs} $container {
						dict for {c2 ds} $cs {
							dict set container2 $b2 $c2 [dict keys $ds]
						}
					}
					dict set return $prev $container2
					unset container2
				}
				set container {}
				set prev $a
			}
			dict set container $b $c $d {}
		}
	}
	return $return
}

if $tcl_interactive return

puts ----
puts [exec date]

set wiki dewiki
set dumppath /public/dumps/public/$wiki

exec touch lastdump
readf lastdump lastdump
set dumplist [glob -tail -directory $dumppath *]

if {[set date [lindex [lsort $dumplist] end-1]] > $lastdump} {
	puts [exec date]
	foreach table {page redirect} {
		exec gzip -dc $dumppath/$date/$wiki-$date-$table.sql.gz | mysql -h [set dbserver tools.labsdb] [set db ${dbuser}__internallinks_p]
	}
	set sql [mysqlconnect -host $dbserver]
	mysqlexec $sql "create database if not exists $db"; mysqluse $sql $db
	#il_count?
	mysqlexec $sql "create table if not exists ${wiki}_$date (il_title varchar(1000), il_link varchar(1000), il_revid_source int(8), il_revid_dest int(8) unsigned, il_count integer\
	 unsigned)"
	foreach pass {firstpass secondpass} {
		#puts $pass;#
		[expat -elementstartcommand tag -characterdatacommand data] parsechannel [bz2 -attach [open $dumppath/$date/$wiki-$date-pages-articles.xml.bz2 rb] -mode c]
		switch $pass {
			firstpass {
				dump firstpass-source [sort $firstpass]
				dump firstpass-dest [set firstpass [sort $firstpass_list]]
			}
			secondpass {
				dump secondpass-dest $secondpass
				dump secondpass-source [sort $secondpass_list]
			}
		}
	}
	mysqlexec $sql {drop table page, redirect}
	dump lastdump $date
}
