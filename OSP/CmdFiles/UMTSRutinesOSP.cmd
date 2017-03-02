@G+
! ----------------------------------------------------------------------------
! "THE BEER-WARE LICENSE" (Revision 42):
! <luisdecameixa@coit.es> wrote this file. As long as you retain this notice you
! can do whatever you want with this stuff. If we meet some day, and you think
! this stuff is worth it, you can buy me a beer in return Luis Diaz Gonzalez
! ----------------------------------------------------------------------------
@G-

@param {site}
@param {chkrnc}

@R-
@trim {site}
@trim {chkrnc}

@log on {site}.Log3G.txt

@gettime {time}
@getdate {date}

@copy {site} {sitepre} 1 3
@copy {site} {sitenum} 4 4

@if {chkrnc} <> 1 then @goto NORNC
@L-
@unset {_lines}
/opt/ericsson/ddc/util/bin/listme | grep '{sitepre}[X-Z]{sitenum}' | cut -d, -f2 | sed 's/^SubNetwork=//g'
@L+
@ifndef {_line1} then @exit
@set {RNC} = {_line1}
@trim {RNC}


@comment [day {date}] [time {time}]
@unset {amoserror}
@unset {_lines}
amos {RNC}
@grep {amoserror} {_lines} "Checking ip contact...OK"
@ifndef {amoserror} then @goto NORNC

lt all
@@ strt
st .{sitenum}
lst .{sitenum}
get iub_{sitepre}.{sitenum}
@@ para ver si es RAN SHARING
lk iub_{sitepre}.{sitenum}
get UtranCell=.*{sitenum} tpsPowerLockState
@@get .{site} maximumTransmissionPower
exit

@label NORNC
@L-
@unset {_lines}
/opt/ericsson/ddc/util/bin/listme | grep -i '{sitepre}[X-Z]{sitenum}'  | cut -d, -f3 | sed 's/^MeContext=//g' | awk -F@ '{print $1" "$2" "$6" "$7}'
@L+
@foreach {_lines} gosub UMTSCHECK
@log off
@R+
@exit

@label UMTSCHECK
@if {_curridx} = 0 then @return
@item {IUB} {_currline} " " 0
@comment {IUB}

@unset {amoserror}
@unset {_lines}
amos {IUB} 
@grep {amoserror} {_lines} "Checking ip contact...OK"
@ifndef {amoserror} then @goto nextiub

lt all
get 0
@@lst node
st cell
@@hgetm alarmport administrative|slogan|oper|normally
alt

@@st auxpluginunit
lga 2
rbs
get . fqband
hget radiolink
@@lh ru fui get vswr 1
@@rbs
@@lh ru fui get vswr 2
@@invxr
cabx
@@rbs
lh ru fm getfaults     
hget RbsLocalCell=S.C. userLabel
lst ret 
get . mix
@@get . maxTotalOutputPower
get feeder
lst tma
lst ret
hget .*,antennabranch tilt
hget .*,retdevice=.$ tilt|usageState|userLabel
get .*,retdevice=.$ ret
exit
@label nextiub
@return