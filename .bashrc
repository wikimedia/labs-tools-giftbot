alias ls='ls -v --color=auto --group-directories-first'
alias grep='grep --color'

alias tclsh='rlwrap -c /data/project/shared/tcl/bin/tclsh8.7'
alias critcl='/data/project/shared/tcl/bin/critcl'
alias nano='jpico'

alias gva='jstart -stderr gva.tcl'
alias vm='jstart -stderr vm.tcl'
alias mg='jstart -stderr mg.tcl'
alias sga='jstart -stderr sga.tcl'
alias gvm='jstart -N gvm -stderr -o /dev/null -mem 5g java -jar GVMBot.jar'
alias gvmhelfer='jstart -stderr gvmhelfer.tcl'

#disable core dumps
ulimit -Sc0

export MANPATH=:/data/project/shared/tcl/man
