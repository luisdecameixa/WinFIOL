@G+
! ----------------------------------------------------------------------------
! "THE BEER-WARE LICENSE" (Revision 42):
! <luisdecameixa@coit.es> wrote this file. As long as you retain this notice you
! can do whatever you want with this stuff. If we meet some day, and you think
! this stuff is worth it, you can buy me a beer in return Luis Diaz Gonzalez
! ----------------------------------------------------------------------------
@G-

@param {site}
@param {eNODE}

@R-
@gettime {time}
@getdate {date}

@trim {site}
@log on {site}.Log4G.txt

@comment [day {date}] [time {time}]

@size {eNODE} {numeNODE}
@set {j} = 0
@while {j} < {numeNODE}
@trim {eNODE[{j}]}
@if {eNODE[{j}]} = * then @goto nexteNODE

@unset {amoserror}
@unset {_lines}
amos {eNODE[{j}]}
@grep {amoserror} {_lines} "Checking ip contact...OK"
@ifndef {amoserror} then @goto nexteNODE

lt all
@@hgetm alarmport administrative|slogan|oper|normally
lst node
st cell
alt

lga 2
rbs
@@st auxpluginunit
@@get . fqband
@@lh ru fui get vswr 1
@@rbs
@@lh ru fui get vswr 2

cabxd
@@rbs

lh ru fm getfaults
get . mix
hget retsubunit cali|elec|operationalstate|userl|iuantAntennaModelNumber
ue print -admitted
@@pmr -m 48 -r 106 | grep Interference
lst tma
lst ret
get . fqband
get feeder
run $scripts/lteUlInt.mos


@@get . beam
@@get . tilt
@@get . electrical
@@get . tma
@@get . ret
@@get . asc

@@license server
exit

@set {eNode_} = {eNODE[{j}]}
@include LTESupervision.cmd

@label nexteNODE
@inc {j}
@endwhile
@log off
@R+
@@end