@G+
! ----------------------------------------------------------------------------
! "THE BEER-WARE LICENSE" (Revision 42):
! <luisdecameixa@coit.es> wrote this file. As long as you retain this notice you
! can do whatever you want with this stuff. If we meet some day, and you think
! this stuff is worth it, you can buy me a beer in return Luis Diaz Gonzalez
! ----------------------------------------------------------------------------
@G-

@param {site}
@param {IUB}
@param {chkrnc}

@R-
@gettime {time}
@getdate {date}

@trim {site}
@trim {IUB}
@trim {chkrnc}

@if {chkrnc} <> 1 then @goto NORNC
@@L-
@unset {_lines}
/opt/ericsson/ddc/util/bin/listme | grep {IUB} | cut -d, -f2 | sed 's/^SubNetwork=//g'
@@L+
@ifndef {_line1} then @goto END
@set {RNC} = {_line1}
@trim {RNC}

@log on {site}.Log3G.txt
@comment [day {date}] [time {time}]

@unset {amoserror}
@unset {_lines}
amos {RNC}
@grep {amoserror} {_lines} "Checking ip contact...OK"
@ifndef {amoserror} then @goto END
lt all
@@ strt
st .{site}
lst .{site}

@size {IUB} {numiub}
@set {j} = 0
@while {j} < {numiub}
@trim {IUB[{j}]}
@if {IUB[{j}]} = * then @goto nextiubrnc
get IubLink=Iub_{IUB[{j}]}
lk iub_{IUB[{j}]}
@label nextiubrnc
@inc {j}
@endwhile
exit

@label NORNC
@size {IUB} {numiub}
@set {j} = 0
@while {j} < {numiub}
@trim {IUB[{j}]}
@if {IUB[{j}]} = * then @goto nextiub

@unset {amoserror}
@unset {_lines}
amos {IUB[{j}]}
@grep {amoserror} {_lines} "Checking ip contact...OK"
@ifndef {amoserror} then @goto nextiub

lt all
get 0
@@lst node
st cell
hgetm alarmport administrative|slogan|oper|normally

lst sau
lst scu
lst sup
alt

lga 2
rbs
@@st auxpluginunit
hget radiolink
@@get . fqband
@@lh ru fui get vswr 1
@@rbs
@@lh ru fui get vswr 2

cabxd
@@rbs

lh ru fm getfaults
get . mix
lst tma
lst ret
get feeder
@@hget .*,antennabranch tilt
@@hget .*,retdevice=.$ tilt|usageState|userLabel
@@get .*,retdevice=.$ ret
@@pmr -r 2 -m 48
@@get . maxTotalOutputPower
@@get . beam
@@get . tilt
@@get . electrical
@@get . tma
@@get . ret
@@get . asc

@@license server
exit
@label nextiub
@inc {j}
@endwhile

@log off
@label END
@R+
@@end