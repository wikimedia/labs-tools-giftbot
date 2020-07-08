alias ls='ls -v --color=auto --group-directories-first'
alias grep='grep --color'

alias tclsh='rlwrap -c /data/project/shared/tcl/bin/tclsh8.7'
alias critcl='/data/project/shared/tcl/bin/critcl'
alias nano='jpico'

alias gva='jstart -stderr -j y -v LC_ALL=$LANG -mem 1g gva.tcl'
alias vm='jstart -stderr -j y -v LC_ALL=$LANG -mem 1g vm.tcl'
alias mg='jstart -stderr -j y -v LC_ALL=$LANG -mem 1g mg.tcl'
alias sga='jstart -stderr -j y -v LC_ALL=$LANG -mem 1g sga.tcl'
alias gvm='jstart -N gvm -stderr -j y -o /dev/null -mem 5g java -jar GVMBot.jar'
alias gvmhelfer='jstart -stderr gvmhelfer.tcl'

#disable core dumps
ulimit -Sc0

export MANPATH=:/data/project/shared/tcl/man
