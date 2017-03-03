@@ ##2G


eaw	GAL70B1
rxtcp:moty=rxotg,cell=Z8889E1;
rxtcp:moty=rxotg,cell=Z6894E2;
exit;
@@ ######

rxcdp:mo=rxotg-10;
rxmop:mo=rxotx-10-0&&-10;
rxmop:mo=rxorx-10;

@clear
@set {site}  = ARA0629
@set {BSC}   = ARA10B1
@set {tg[0]} = 2038
@set {tg[1]} = 870
@set {tg[2]} = *
@set {tg[3]} = *
@set {tg[4]} = *
@include GSMRutinesAlarmsV3.cmd

@@ que celdas estan en el TG
eaw MAD06B6
rxtcp:mo=rxotg-10;
rxmop:mo=rxotg-10;
exit;

@@ sacar TG asociado a una celda
rxtcp:moty=rxotg,cell=CM14052;
rxtcp:moty=rxotg,cell=R6020R1;
exit;

@@ 3G
@@ 3G MAD
telnet -a 10.192.147.200
Ericss-1

@@ 3G BAD
telnet -a 10.192.143.71
Ericss-1
@@ RNC
@clear
@preserve
@@-----------------------
@set {site} = GAL9725
@@-----------------------
@copy {site} {sitepre} 1 3
@copy {site} {sitenum} 4 4

/opt/ericsson/ddc/util/bin/listme | grep '{sitepre}[X-Z]{sitenum}' | cut -d, -f2 | sed 's/.*SubNetwork=//g'
@item {RNC} {_line1} " " 0
@comment {RNC}

amos MAD01R05

lt all
st .{sitenum}
lst .{sitenum}
get iub_{sitepre}.{sitenum}
@@ para ver si es RAN SHARING
lk iub_{sitepre}.{sitenum}
exit

/opt/ericsson/ddc/util/bin/listme | grep '{sitepre}[X-Z]{sitenum}' | sed 's/.*MeContext=//g' | awk -F@ '{print $1" "$2" "$6" "$7}'

amos GALX4801

lt all
hgetm alarmport administrative|slogan|oper
lst node
st cell
alt
get feeder

lga 120 | grep MENOR
lga 120 | grep AlarmPort=9

lga 30 | grep "RruDeviceGroup_RetPortCurrentTooHigh"

st auxpluginunit
get . ^f.*band
get . mix
@@get . noise
@@lh ru fui get vswr 1
@@rbs
@@lh ru fui get vswr 2

invxr
cabx
rbs

pmr -r 3 -m 8 | grep "Sector=1,Carrier=2"
rbs

lh ru fm getfaults
hget RbsLocalCell=S.C. userLabel
hget .*,antennabranch tilt
hget .*,retdevice=.$ tilt|usageState|userLabel
get .*,retdevice=.$ ret


exit

lst tma
lst ret
lst asc

pmr -r 1 -m 0.25

hget . beam
hget . antennatilt
hget . rach
hget . electrical
hget . retdevice tilt
st sau
st sup
exit

lh ru fui help -l
lh ru fui get devstat
lh ru fui get adcpar
lh ru fui get temp

@@ Para analizar el historico de RSSI
@getdate {hoy} yyyymmdd
@set {ayer} = {hoy} - 1
@@ RSSI media en el periodo
pmr -r 1 -s {ayer}.2200 -e {ayer}.2215
@@ RSSI/h (las ultimas 48h)
pmr -r 3 -m 24 | grep "Sector=1,Carrier=2"
@@@@@@

@@ ##LTE
exit

@@ 4G
telnet -a 10.118.232.13
Ericss-1
@clear
@preserve
@@-----------------------
@set {site} = GAL9725
@@-----------------------
@copy {site} {sitepre} 1 3
@copy {site} {sitenum} 4 4
/opt/ericsson/ddc/util/bin/listme | grep '{sitepre}[X-Z]{sitenum}'  | cut -d, -f3 | sed 's/^MeContext=//g' | awk -F@ '{print $1"  "$2"  "$6" "$7}'

amos CYLX9546L

lt all
@@ hgetm alarmport administrative|slogan|oper
lst node
st cell
alt

lga 360 | grep "Service Degraded.*CLMX0002M1A"
rbs

st auxpluginunit
get . ^f.*band$  !Band 7 = 2600 L ! !Band 20 = 800 M ! !Band 3 = 1800 N!
get . mix
lh ru fui get vswr 1
rbs
lh ru fui get vswr 2
@@ lga |grep  ResourceConfigurationFailure
cabx
rbs

lh ru fm getfaults

hget retsubunit cali|elec|operationalstate|userl|iuantAntennaModelNumber
ue print -admitted

run $scripts/lteUlInt.mos

run $scripts/lteUlInt_BB5216.mos

pmr -m 8

exit

hget . ^cellId$
ue print -admitted

lst tma
lst ret
lst asc
@@pmr -r 1 -m 0.25

get . beam
get . tilt
get . rach
get . electrical
st sau
st sup
exit

run $scripts/rssi_monitor.mos 50

@@ medir el RSSI en 4G (da informaci¢n de las horas previas)
pmr -m 8 -r 103 | grep 'Interference'
rbs
pmr -m 13 -r 106 | grep UlThroughput_kbps

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@clear
@set {site}    = MAD6241
@set {BSC}     = CAT80B1
@set {cell[0]} = G9301E1
@set {cell[1]} = *
@set {cell[2]} = *
@set {cell[3]} = *
@include GSMRutinesCell.cmd
@execwait alarms2gdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}
@execwait rxelpdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}

eaw GAL70B1
rxtcp:moty=rxotg,cell=G9200E1;

exit;

telnet -a 10.192.143.199
Ericss-1

@clear
@set {site}  = GAL0235 
@set {BSC}   = GAL60B3 
@set {tg[0]} = 249
@set {tg[1]} = *
@set {tg[2]} = *
@set {tg[3]} = *
@set {tg[4]} = *
@include GSMRutinesAlarmsV3.cmd
@execwait alarms2gdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}
@execwait rxelpdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}

@@ 3G MAD
telnet -a 10.192.147.200
Ericss-1
@@ 3G BAD
@@telnet -a 10.192.143.77
@@Ericss-1

@clear
@set {site}   = CYL8718 
@set {chkrnc} = 1
@include UMTSRutinesOSP.cmd
exit

@@ 4G
telnet -a 10.118.232.12
Ericss-1
@clear
@set {site} = CYL8718 
@include LTERutinesOSPV2.cmd
exit

/opt/ericsson/ddc/util/bin/listme | grep 'GALX9550'

ping 10.9.229.233
ping -s 10.9.229.137 56 10
traceroute 10.9.229.137
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@clear
@set {site}  = TEST
@set {BSC}   = CAT60B3
@set {indice} = 0  ! no tocar
@set {numero} = 0
@while {numero} <= 2047
	@set {tg[{indice}]} = {numero}
	@inc {indice}
	@inc {numero}
@endwhile
@include GSMRutinesAlarmsV3.cmd
@execwait alarms2gdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}
@execwait rxelpdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}

@@ RU
lh ru fui help -l
lh ru fui get devstat
lh ru fui get adcpar
lh ru fui get temp
lh ru fui read modem switch
lh ru fui read ret signal
lh ru fui read ret power
lh ru fui read modem gain tx
lh ru fui read modem gain rx
st auxpluginunit
st rfport
st riport
get riport remoteRiPortRef
@@@@@@@@@

@include OSPUberChecker.cmd


eaw GAL01B3
@log on AlarmasHW2G.log
ioexp;
rxmfp:moty=rxocf;
rxmop:moty=rxotg;
rxmfp:moty=rxocf,faulty;
rxmfp:moty=rxotrx,faulty;
rxmfp:moty=rxotx,faulty;
rxmfp:moty=rxorx,faulty;
rxmfp:moty=rxomctr,faulty;
rxmfp:moty=rxotf,faulty;
@L-
exit;


@@@ Crea BBDD 2G (BSC, Cells) de OSP
eac_esi_config -nelist | grep '.*B[1-9]' | sort | uniq
@unset {_line0}
@size {_lines} {nBSC}
@FOREACH {_lines} ITEM {BSC[{_CURRIDX}]} {_LINES[{_CURRIDX}]} " " 0
@set {i} = 1
@size {_lines} {nBSC}
@log on OSP2GDB.txt
@foreach {BSC} @gosub CHECKBSC
@L-
@exit

@label CHECKBSC
@if {i}={nBSC} then return
eaw {BSC[{i}]}
rxtcp:moty=rxotg;
@T 2
exit;
@inc {i}
@return
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@clear
@set {BSC} = GAL01B3
@include GSMHWAlarms.cmd

@execute perl alarms2g.pl



eaw GAL60B4
rlcrp:cell=G1582E1;
rlcrp:cell=G1582E2;
rlcrp:cell=G1582E3;
rlcrp:cell=CX82IG1;
rlcrp:cell=CX82IG2;
rlcrp:cell=CX82IG3;
@@rxmsp:mo=rxotg-148,subord;
rxmfp:mo=rxotg-148,subord,faulty;
exit;
@T 5



@log on HOTSWAP.txt
@@ 3G MAD
telnet -a 10.192.147.203
Ericss-1

amos CYLX1549
lt all
cabx
rbs
exit

@T 1
@@amos GALY1577
@@lt all
@@cabx
@@rbs
@@exit
@@exit

@T 1
@@ 4G
telnet -a 10.118.232.13
Ericss-1

amos CYLX1549L
lt all
st cell
@@cabx
@@rbs
@@run $scripts/lteUlInt.mos
exit
exit
@log off