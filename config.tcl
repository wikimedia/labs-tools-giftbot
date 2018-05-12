# Ausrufer config template

# Copyright 2010 Giftpflanze

# This file is part of Ausrufer.

# Ausrufer is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.

# modes:
#  0 update database
#  1 deliver changes + 0
#  2 test changes
#set mode 0; lappend get / rvstart 20110725000000
set mode 1
#lappend get / rvstart 20110502000000
#set mode 2

# create database:
#  run 1:
#set mode 0; lappend get / rvstart 20131209000000
#  run 2:
#set mode 0; lappend get / rvstart 20131216000000

set page Benutzer:$self/Ausrufer

# Terse format
set presep {}
set itemsep <br>\n
set listsep {, }
set intersep { }

# More clearly arranged but longer format
#set presep {* }
#set itemsep \n
#set listsep "\n** "
#set intersep $listsep

set hiddenpages {}

return
