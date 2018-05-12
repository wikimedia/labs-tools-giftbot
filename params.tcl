# params.tcl Library

# API parameter patterns

# Copyright 2010, 2011, 2012 Giftpflanze

# This file is part of the MediaWiki Tcl Bot Framework.

# The MediaWiki Tcl Bot Framework is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

set query "$format / action query"
set get "$query / prop revisions / rvprop content / rvlimit 1"; # / titles ~ / rvprop content|timestamp / rvsection ~ / rvstart ~
set put "$format / action edit / assert user"; # / bot true / title ~ / text ~ / summary ~ / section [new] / minor true
set flagged "$query / prop revisions / rvprop flagged|ids|comment|user|timestamp"
set logevents "$query / list logevents"
set catmem "$query / list categorymembers / cmlimit max / cmprop title"; #|sortkeyprefix"; # / cmtitle (Category:)~
set embeddedin "$query / list embeddedin / eilimit max"; # / eititle (Template:)~
set allpages "$query / list allpages / aplimit max"; # / apnamespace ~ / apprefix/apfrom ~
set lastcontrib "$query / list usercontribs / uclimit 1 / ucprop timestamp"; # ucuser ~
set redirect "$query / prop info / redirects true"; # titles ~

return
