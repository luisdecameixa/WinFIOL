@G+
! ----------------------------------------------------------------------------
! "THE BEER-WARE LICENSE" (Revision 42):
! <luisdecameixa@coit.es> wrote this file. As long as you retain this notice you
! can do whatever you want with this stuff. If we meet some day, and you think
! this stuff is worth it, you can buy me a beer in return Luis Diaz Gonzalez
! ----------------------------------------------------------------------------
@G-

@param {site}

@R-
@trim {site}

@log on {site}.Log4G.txt

@gettime {time}
@getdate {date}

@copy {site} {sitepre} 1 3
@copy {site} {sitenum} 4 4
@L-
@unset {_lines}
/opt/ericsson/ddc/util/bin/listme | grep '{sitepre}[X-Z]{sitenum}'  | cut -d, -f3 | sed 's/^MeContext=//g' | awk -F@ '{print $1"  "$2"  "$6" "$7}'
@L+
@ifndef {_line1} then @exit
@comment [day {date}] [time {time}]

@foreach {_lines} gosub LTECHECK
@log off
@R+
@exit

@label LTECHECK
@if {_curridx} = 0 then @return
@item {eNODE} {_currline} " " 0
@comment {eNODE}

@unset {amoserror}
@unset {_lines}
amos {eNODE}
@grep {amoserror} {_lines} "Checking ip contact...OK"
@ifndef {amoserror} then @goto nextenode

lt all
rbs
rbs

get 0
@@hgetm alarmport administrative|slogan|oper|normally
lst node
st cell
alt

lga 2
@@rbs
@@st auxpluginunit
get . mix
@@get . ^f.*band$
@@lh ru fui get vswr 1
@@rbs
@@lh ru fui get vswr 2

cabx
@@rbs

lh ru fm getfaults
hget antennaunit.* mechanical.*tilt
hget retsubunit cali|elec|operationalstate|userl|iuantAntennaModelNumber
ue print -admitted
lst tma
lst ret
get feeder
@@pmr -m 48 -r 106 | grep Interference

@@ checking RSSI
@L-
get 0 logicalName > $name
@L+
if $name
run $scripts/lteUlInt.mos
else
run $scripts/lteUlInt_BB5216.mos
fi

exit
@label nextenode
@return