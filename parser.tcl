#!/data/project/shared/tcl/bin/tclsh8.7

package require pt::pgen
package require pt::peg::interp
package require pt::peg::container

set grammar [read [open wikitext.peg]]
puts [open parser-critcl.tcl w] [pt::pgen peg $grammar critcl -package wikitext -class wikitext::parser]
