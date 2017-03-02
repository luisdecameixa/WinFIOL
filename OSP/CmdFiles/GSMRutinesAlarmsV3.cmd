@G+
! ----------------------------------------------------------------------------
! "THE BEER-WARE LICENSE" (Revision 42):
! <luisdecameixa@coit.es> wrote this file. As long as you retain this notice you
! can do whatever you want with this stuff. If we meet some day, and you think
! this stuff is worth it, you can buy me a beer in return Luis Diaz Gonzalez
! ----------------------------------------------------------------------------
@G-

@param {site}
@param {BSC}
@param {tg}

@R-
@gettime {time}
@getdate {date}

@trim {BSC}
@trim {site}
@if {site} = * then @set {site} = {BSC}

@set {FileAlarms} = "GSM.ALARMS.TXT"
@set {TitleFileAlarms} = "ALARMS SUMMARY  [ " + {site} + " " + {BSC} + " ]  ALARMS SUMMARY"
@write {TitleFileAlarms} {FileAlarms}
@unset {TitleFileAlarms}

@log on {site}.Log2G.{BSC}.txt
@comment [day {date}] [time {time}]
eaw {BSC};
@gosub CHECKTG
exit;

@@ display alarm's file
@read {FileAlarms} {data}
@foreach {data} comment {_currline}

@log off
@R+
@exit

@label CHECKTG
@size {tg} {numtg}
@set {j} = 0
@while {j} < {numtg}
	@trim {tg[{j}]}
	@if {tg[{j}]} <> * then @gosub Rutina2G
	@inc {j}
@endwhile
@return

@label Rutina2G
@comment #################### TG-{tg[{j}]} ####################
@@ hitorico de alarmas
rxelp:mo=rxotg-{tg[{j}]};

@@ saber si hay transmision/comunicacion
rxtei:mo=rxocf-{tg[{j}]};
@@rxapp:moty=rxotg;
@@
rxcdp:mo=rxotg-{tg[{j}]};
@@@iferror then @return
@@@unset {tx}
@@@unset {ttx}
@@@grep {tx} {_lines} "^RXOTX-.*"
@@@ifndef {tx} then @return
@@@cut {ttx} {tx} col 1
@@@comment TRX-RU CELL-TRX
@@@foreach {ttx} @gosub TRXRU_CELLTRX

@@ estado del MO
rxmsp:mo=rxotg-{tg[{j}]},subord;
@iferror then @return

@@ CELLS CHECKER
rxtcp:mo=rxotg-{tg[{j}]};
@unset {lineas}
@merge {lineas} = {_lines}
@compact {lineas}

@unset {found}
@grep {found} {lineas[3]} ".*CELL.*"
@ifndef {found} then @comment CELLS NOT FOUND
@ifndef {found} then @return

@set {i} = 4
@set {cellidx} = 0
@unset {celda[{cellidx}]}
@set {linea} =  {lineas[{i}]}
@cut {tmpcell} {linea} col 2
@set {celda[{cellidx}]} = {tmpcell}

@label BUCLE
@inc {i}
@inc {cellidx}
@set {linea} = {lineas[{i}]}
@cut {tmpcell} {linea} col 1
@set {celda[{cellidx}]} = {tmpcell}
@if {tmpcell} <> "END" then goto BUCLE
@unique {celda}
@gosub CHECKCELDA
@return

@label CHECKCELDA
@set {cellidx} = 0
@while {celda[{cellidx}]} <> "END"
	@comment {celda[{cellidx}]} TG-{tg[{j}]}

	@@ NEIGHBOUR
	@@comment NEIGHBOUR
	@@rlnrp:cell={celda[{cellidx}]},cellr=all;
	@@iferror then goto NEXTCHECKCELDA

	@@ power
	@comment POWER
	rlcpp:cell={celda[{cellidx}]};
	@iferror then goto NEXTCHECKCELDA

    @@ CELL DESCRIPTION
	rldep:cell={celda[{cellidx}]};
	@iferror then goto NEXTCHECKCELDA

    @@ check the frequency
	@comment CheckFrequency
	rlcfp:cell={celda[{cellidx}]};
	@iferror then goto NEXTCHECKCELDA

	@@ check cell barred CB=YES
	@comment CheckCellBarred
	rlsbp:cell={celda[{cellidx}]};
	@iferror then goto NEXTCHECKCELDA

    @@ check if hopping is enabled
	@comment HOPPING
	rlchp:cell={celda[{cellidx}]};
	@iferror then goto NEXTCHECKCELDA

	@@ check GPRS
	@comment CheckGPRS
	rlgsp:cell={celda[{cellidx}]};
    @iferror then goto NEXTCHECKCELDA

    @@ check EDGE
	@comment CheckEDGE
	rlbdp:cell={celda[{cellidx}]};
    @iferror then goto NEXTCHECKCELDA

	@@ Signalling and status of channel configuration
	rlcrp:cell={celda[{cellidx}]};
    @iferror then goto NEXTCHECKCELDA

	rlstp:cell={celda[{cellidx}]};
	@iferror then goto NEXTCHECKCELDA

	rlslp:cell={celda[{cellidx}]};
	@iferror then goto NEXTCHECKCELDA

@label NEXTCHECKCELDA
	@inc {cellidx}
@endwhile

@@ FAULT CODES CHECKER
rxmfp:mo=rxotg-{tg[{j}]},subord,faulty;
@unset {lineas}
@merge {lineas} = {_lines}
@compact {lineas}
@gosub FAULTCODESCHECK
@@
@return

@@ @@@@@@@@@@@@@@@@@@@@@@@
@@ SUBRUTINES
@@ @@@@@@@@@@@@@@@@@@@@@@@

@label TRXRU_CELLTRX
@@ TRX con RU
rxmfp:mo={_currline};
@@ celdas con TRX   
rxmop:mo={_currline}; 
@return

@label FAULTCODESCHECK
@unset {idx}
@find {idx} {lineas} "^MO .*"
@ifndef {idx} then @return

@while {lineas[{idx}]} <> "END"
    @unset {foundCC}
	@unset {foundRU}

	@@ write MO
	@grep  {foundCC} {lineas[{idx}]} "^MO .*"
	@ifdef {foundCC} then @gosub WRITEMO
    @ifdef {foundCC} then @goto continue

	@@ write FAULT CODES CLASS
	@grep  {foundCC} {lineas[{idx}]} "^FAULT CODES CLASS.*"
	@ifdef {foundCC} then @set {internal} = 1
	@ifdef {foundCC} then @gosub PROCESSFAULTCODESCLASS
    @ifdef {foundCC} then @goto continue

	@@ write EXTERNAL FAULT CODES CLASS
	@grep  {foundCC} {lineas[{idx}]} "^EXTERNAL FAULT CODES CLASS.*"
    @ifdef {foundCC} then @set {internal} = 0
	@ifdef {foundCC} then @gosub PROCESSFAULTCODESCLASS
    @ifdef {foundCC} then @goto continue


	@@ write REPLACEMENT UNITS
	@grep  {foundRU} {lineas[{idx}]} "^REPLACEMENT UNITS$"
	@ifdef {foundRU} then @gosub PROCESSREPLACEMENTUNITS

	@label continue
	@inc {idx}
	@unset {internal}
@endwhile
@return


@label WRITEMO
@append {FileAlarms} " "
@inc {idx}
@set {linea} = {lineas[{idx}]}
@cut {MO} {linea} col 1
@before {MOshort} {MO} "-"
@replace {MOshort} "RXO" " "
@trim {MOshort}

@@ MOshort -> TRXC = TRX
@if {MOshort} = "TRX" then @set {MOshort} = {MOshort} + "C"

@append {FileAlarms} {MO}
@@append {FileAlarms} {MOshort}
@return

@label PROCESSFAULTCODESCLASS
@append {FileAlarms} {foundCC}
@ritem {code1} {foundCC} " " 0
@@append {FileAlarms} {code1}
@inc {idx}
@set {linea} = {lineas[{idx}]}
@append {FileAlarms} {linea}

@set {n} = 0
@set {code2} = " "
@while {code2} <> ""
	@item {code2} {linea} " " {n}
	@if {code2} = "" then @goto nextcode2
    @gosub SEEKALARMCOMMENT
	@inc {n}
	@label nextcode2
@endwhile
@return


@label PROCESSREPLACEMENTUNITS
@append {FileAlarms} {foundRU}
@inc {idx}
@set {linea} = {lineas[{idx}]}
@append {FileAlarms} {linea}

@set {n} = 0
@set {coderu} = " "
@while {coderu} <> ""
	@item {coderu} {linea} " " {n}
	@if {coderu} = "" then @goto nextcoderu
    @gosub SEEKRUCOMMENT
	@inc {n}
	@label nextcoderu
@endwhile
@return



@label SEEKALARMCOMMENT
@unset {alarm}
@ifndef {internal} then @goto OUTSEEKALARMCOMMENT
@if {internal} = 1 then @set {PatternToSeek} = {MOshort} + " " + "I" + {code1} + ":" + {code2}
@if {internal} = 0 then @set {PatternToSeek} = {MOshort} + " " + "EC" + {code1} + ":" + {code2}


@if {PatternToSeek} = "CF I1A:0" then @set {alarm} = "Reset, Automatic Recovery"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:1" then @set {alarm} = "Reset, Power On"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:2" then @set {alarm} = "Reset, Switch"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:3" then @set {alarm} = "Reset, Watchdog"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:4" then @set {alarm} = "Reset, SW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:5" then @set {alarm} = "Reset, RAM Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:6" then @set {alarm} = "Reset, Internal Function Change"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:7" then @set {alarm} = "XBus Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:8" then @set {alarm} = "Timing Unit VCO Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:9" then @set {alarm} = "Timing Bus Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:10" then @set {alarm} = "Indoor Temp Out of Safe Range"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "CF I1A:12" then @set {alarm} = "DC Voltage Out of Range"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "CF I1A:14" then @set {alarm} = "Bus Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:15" then @set {alarm} = "IDB Corrupted"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:16" then @set {alarm} = "RU Database Corrupted"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:17" then @set {alarm} = "HW and IDB Inconsistent"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:18" then @set {alarm} = "Internal Configuration Failed"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:19" then @set {alarm} = "HW and SW Inconsistent"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:21" then @set {alarm} = "HW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:22" then @set {alarm} = "Air Time Counter Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:23" then @set {alarm} = "Time Distribution Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I1A:24" then @set {alarm} = "Temperature Close to Destructive Limit"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "CF I2A:1" then @set {alarm} = "Reset, Power On"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:2" then @set {alarm} = "Reset, Switch"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:3" then @set {alarm} = "Reset, Watchdog"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:4" then @set {alarm} = "Reset, SW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:5" then @set {alarm} = "Reset, RAM Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:6" then @set {alarm} = "Reset, Internal Function Change"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:7" then @set {alarm} = "RX Internal Amplifier Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:8" then @set {alarm} = "VSWR Limits Exceeded"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:9" then @set {alarm} = "Power Limits Exceeded"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:10" then @set {alarm} = "DXU-Opt EEPROM Checksum Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:12" then @set {alarm} = "RX Maxgain/Mingain Violated"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:13" then @set {alarm} = "Timing Unit VCO Ageing"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:14" then @set {alarm} = "CDU Supervision/Communication Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:15" then @set {alarm} = "VSWR/Output Power Supervision Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:16" then @set {alarm} = "Indoor Temp Out of Normal Conditional Range"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:17" then @set {alarm} = "Indoor Humidity"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:18" then @set {alarm} = "DC Voltage Out of Range"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:19" then @set {alarm} = "Power and Climate System in Standalone Mode"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "CF I2A:21" then @set {alarm} = "Internal Power Capacity Reduced"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:22" then @set {alarm} = "Battery Backup Capacity Reduced"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:23" then @set {alarm} = "Climate Capacity Reduced"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:24" then @set {alarm} = "HW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:25" then @set {alarm} = "Loadfile Missing in DXU or ECU"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:26" then @set {alarm} = "Climate Sensor Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:27" then @set {alarm} = "System Voltage Sensor Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:28" then @set {alarm} = "A/D Converter Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:29" then @set {alarm} = "Varistor Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:30" then @set {alarm} = "Bus Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:31" then @set {alarm} = "High Frequency of Software Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:32" then @set {alarm} = "Non-volatile Memory Corrupted"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:33" then @set {alarm} = "RX Diversity Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:34" then @set {alarm} = "Output Voltage Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:35" then @set {alarm} = "Optional Synchronization Source"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:36" then @set {alarm} = "RU Database Corrupted"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:37" then @set {alarm} = "Circuit Breaker Tripped or Fuse Blown"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:38" then @set {alarm} = "Default Values Used"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:39" then @set {alarm} = "RX Cable Disconnected"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:40" then @set {alarm} = "Reset, DXU Link Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:41" then @set {alarm} = "Lost Communication to TRU"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:42" then @set {alarm} = "Lost Communication to ECU"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:43" then @set {alarm} = "Internal Configuration Failed"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:44" then @set {alarm} = "ESB Distribution Failure"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:45" then @set {alarm} = "High Temperature"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:46" then @set {alarm} = "DB Parameter Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:47" then @set {alarm} = "Antenna Hopping Failure"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:48" then @set {alarm} = "GPS Synch Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:49" then @set {alarm} = "Battery Backup Time Shorter Than Expected"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:50" then @set {alarm} = "RBS Running on Battery"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:51" then @set {alarm} = "TMA Supervision/Communications Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:52" then @set {alarm} = "CXU Supervision/Communication Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:53" then @set {alarm} = "HW and IDB Inconsistent"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:54" then @set {alarm} = "Timing Bus Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:55" then @set {alarm} = "XBus Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:57" then @set {alarm} = "RX Path Imbalance"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:58" then @set {alarm} = "Disconnected"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:59" then @set {alarm} = "Operating Temperature Too High, Main Load"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:60" then @set {alarm} = "Operating Temperature Too High, Battery"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:61" then @set {alarm} = "Operating Temperature Too High, Capacity Reduced"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:62" then @set {alarm} = "Operating Temperature Too Low, Capacity Reduced"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:63" then @set {alarm} = "Operating Temperature Too High, No Service"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:64" then @set {alarm} = "Operating Temperature Too Low, Communication"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:65" then @set {alarm} = "Battery Voltage Too Low, Main Load Disconnected"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:66" then @set {alarm} = "Battery Voltage Too Low, Prio Load Disconnected"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:67" then @set {alarm} = "System Undervoltage"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:68" then @set {alarm} = "System Overvoltage"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:69" then @set {alarm} = "Cabinet Product Data Mismatch"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:70" then @set {alarm} = "Battery Missing"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:71" then @set {alarm} = "Low Battery Capacity"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:72" then @set {alarm} = "Software Load of RUS Failed"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:73" then @set {alarm} = "Degraded or Lost Communication to Radio Unit"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:79" then @set {alarm} = "Configuration Fault of CPRI System"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:80" then @set {alarm} = "Antenna System DC Power Supply Overloaded"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:81" then @set {alarm} = "Primary Node Disconnected"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:82" then @set {alarm} = "Radio Unit Incompatible"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:83" then @set {alarm} = "Radio Unit Connection Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:84" then @set {alarm} = "Unauthorized External Process Hunt"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:85" then @set {alarm} = "Unused MCPA, Capacity Reduced"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:86" then @set {alarm} = "Low Battery Capacity, Battery Test"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:87" then @set {alarm} = "Radio Unit HW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:88" then @set {alarm} = "CPRI Delay Too Long"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:89" then @set {alarm} = "DU Degraded - TRX functionality lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:90" then @set {alarm} = "Ring Redundancy Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:91" then @set {alarm} = "Fan Power Reduced"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:92" then @set {alarm} = "Secondary node Disconnected"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:93" then @set {alarm} = "Alarm Port Inconsistent Configuration"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF I2A:94" then @set {alarm} = "Feeder Connectivity Fault"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "CF EC1B:2" then @set {alarm} = "LMT (BTS Locally Disconnected)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC1B:4" then @set {alarm} = "L/R SWI (BTS in Local Mode)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC1B:5" then @set {alarm} = "L/R TI (Local to Remote While Link Lost)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC1B:9" then @set {alarm} = "Smoke Alarm"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "CF EC2B:2" then @set {alarm} = "Limited Super Channel Support"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC2B:3" then @set {alarm} = "Smoke Alarm Faulty"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC2B:4" then @set {alarm} = "TP (Technician Present)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC2B:5" then @set {alarm} = "Alarm Suppr"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC2B:6" then @set {alarm} = "O&M Link Disturbed"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC2B:9" then @set {alarm} = "RBS DOOR (RBS Cabinet Door Open)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC2B:10" then @set {alarm} = "MAINS FAIL (External Power Source Failure)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC2B:11" then @set {alarm} = "ALNA/TMA Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC2B:12" then @set {alarm} = "ALNA/TMA Degraded"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC2B:13" then @set {alarm} = "Auxiliary Equipment Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CF EC2B:14" then @set {alarm} = "Battery Backup External Fuse Fault"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "TRXC I1A:0" then @set {alarm} = "Reset, Automatic Recovery"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:1" then @set {alarm} = "Reset, Power On"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:2" then @set {alarm} = "Reset, Switch"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:3" then @set {alarm} = "Reset, Watchdog"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:4" then @set {alarm} = "Reset, SW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:5" then @set {alarm} = "Reset, RAM Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:6" then @set {alarm} = "Reset, Internal Function Change"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "TRXC I1A:8" then @set {alarm} = "Timing Reception Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:9" then @set {alarm} = "Signal Processing Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:10" then @set {alarm} = "RX Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:11" then @set {alarm} = "DSP CPU Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:12" then @set {alarm} = "Terrestrial Traffic Channel Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:13" then @set {alarm} = "RF Loop Test Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:14" then @set {alarm} = "RU Database Corrupted"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:15" then @set {alarm} = "X Bus Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:16" then @set {alarm} = "Initiation Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:17" then @set {alarm} = "X Interface Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:18" then @set {alarm} = "DSP Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:19" then @set {alarm} = "Reset, DXU Link Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:20" then @set {alarm} = "HW and IDB Inconsistent"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:21" then @set {alarm} = "Internal Configuration Failed"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:22" then @set {alarm} = "Voltage Supply Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:23" then @set {alarm} = "Air Time Counter Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:24" then @set {alarm} = "High Temperature"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:25" then @set {alarm} = "TX/RX Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:26" then @set {alarm} = "Radio Control System Load"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:27" then @set {alarm} = "Traffic Lost Downlink"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:28" then @set {alarm} = "Traffic Lost Uplink"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:29" then @set {alarm} = "Y Link Communication HW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:30" then @set {alarm} = "DSP RAM Soft Error"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:31" then @set {alarm} = "Memory Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:32" then @set {alarm} = "UC/HC Switch Card/Cable Missing or Corrupted"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:33" then @set {alarm} = "Low Temperature"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:34" then @set {alarm} = "Radio Unit HW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:35" then @set {alarm} = "Radio Unit Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:36" then @set {alarm} = "Lost Communication to Radio Unit"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1A:37" then @set {alarm} = "Radio Unit Communication Failure"
@ifdef {alarm} then  @goto SALIENDO


@if {PatternToSeek} = "TRXC I1B:0" then @set {alarm} = "CDU/Combiner Not Usable"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1B:1" then @set {alarm} = "Indoor Temp Out of Safe Range"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1B:3" then @set {alarm} = "DC Voltage Out of Range"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1B:7" then @set {alarm} = "TX Address Conflict"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1B:8" then @set {alarm} = "Y Link Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1B:9" then @set {alarm} = "Y Link Communication Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1B:10" then @set {alarm} = "Timing Reception Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1B:11" then @set {alarm} = "X Bus Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1B:12" then @set {alarm} = "TRX Not Activated for Combined Cell"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I1B:13" then @set {alarm} = "Frequency Bandwidth Mismatch"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "TRXC I2A:0" then @set {alarm} = "RX Cable Disconnected"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:1" then @set {alarm} = "RX EEPROM Checksum Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:2" then @set {alarm} = "RX Config Table Checksum Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:3" then @set {alarm} = "RX Synthesizer Unlocked"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:4" then @set {alarm} = "RX Internal Voltage Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:5" then @set {alarm} = "RX Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:6" then @set {alarm} = "TX Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:7" then @set {alarm} = "TX EEPROM Checksum Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:8" then @set {alarm} = "TX Config Table Checksum Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:9" then @set {alarm} = "TX Synthesizer Unlocked"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:10" then @set {alarm} = "TX Internal Voltage Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:11" then @set {alarm} = "TX High Temperature"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:12" then @set {alarm} = "TX Output Power Limits Exceeded"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:13" then @set {alarm} = "TX Saturation"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:14" then @set {alarm} = "Voltage Supply Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:15" then @set {alarm} = "VSWR/Output Power Supervision Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:16" then @set {alarm} = "Non-volatile Memory Corrupted"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:17" then @set {alarm} = "Loadfile Missing for TRX node"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:18" then @set {alarm} = "DSP Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:19" then @set {alarm} = "High Frequency of Software Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:20" then @set {alarm} = "RX Initiation Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:21" then @set {alarm} = "TX Initiation Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:22" then @set {alarm} = "CDU-Bus Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:23" then @set {alarm} = "Default Values Used"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:24" then @set {alarm} = "Radio Unit Antenna System Output Voltage Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:25" then @set {alarm} = "TX Max Power Restricted"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:26" then @set {alarm} = "DB Parameter Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:29" then @set {alarm} = "Power Amplifier Fault"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "TRXC I2A:32" then @set {alarm} = "RX High Temperature"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:33" then @set {alarm} = "Inter TRX Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:36" then @set {alarm} = "RX Filter Loadfile Checksum Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:37" then @set {alarm} = "RX Internal Amplifier Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:39" then @set {alarm} = "RF Loop Test Fault, Degraded RX"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:40" then @set {alarm} = "Memory Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:41" then @set {alarm} = "IR Memory Not Started"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:42" then @set {alarm} = "UC/HC Switch Card/Cable and IDB Inconsistent"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:43" then @set {alarm} = "Internal HC Load Power Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:44" then @set {alarm} = "TX Low Temperature"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:45" then @set {alarm} = "Radio Unit HW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:46" then @set {alarm} = "Traffic Performance Uplink"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC I2A:47" then @set {alarm} = "Internal Configuration Failed"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "TRXC EC1B:4" then @set {alarm} = "L/R SWI (TRU in Local Mode)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC1B:5" then @set {alarm} = "L/R TI (Local to Remote While Link Lost)"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "TRXC EC2B:6" then @set {alarm} = "O&M Link Disturbed"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:16" then @set {alarm} = "TS0 TRA Lost (TS Mode Is IDLE)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:17" then @set {alarm} = "TS0 TRA Lost (TS Mode Is CS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:18" then @set {alarm} = "TS0 PCU Lost (TS Mode Is PS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:20" then @set {alarm} = "TS1 TRA Lost (TS Mode Is IDLE)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:21" then @set {alarm} = "TS1 TRA Lost (TS Mode Is CS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:22" then @set {alarm} = "TS1 PCU Lost (TS Mode Is PS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:24" then @set {alarm} = "TS2 TRA Lost (TS Mode Is IDLE)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:25" then @set {alarm} = "TS2 TRA Lost (TS Mode Is CS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:26" then @set {alarm} = "TS2 PCU Lost (TS Mode Is PS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:28" then @set {alarm} = "TS3 TRA Lost (TS Mode Is IDLE)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:29" then @set {alarm} = "TS3 TRA Lost (TS Mode Is CS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:30" then @set {alarm} = "TS3 PCU Lost (TS Mode Is PS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:32" then @set {alarm} = "TS4 TRA Lost (TS Mode Is IDLE)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:33" then @set {alarm} = "TS4 TRA Lost (TS Mode Is CS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:34" then @set {alarm} = "TS4 PCU Lost (TS Mode Is PS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:36" then @set {alarm} = "TS5 TRA Lost (TS Mode Is IDLE)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:37" then @set {alarm} = "TS5 TRA Lost (TS Mode Is CS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:38" then @set {alarm} = "TS5 PCU Lost (TS Mode Is PS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:40" then @set {alarm} = "TS6 TRA Lost (TS Mode Is IDLE)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:41" then @set {alarm} = "TS6 TRA Lost (TS Mode Is CS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:42" then @set {alarm} = "TS6 PCU Lost (TS Mode Is PS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:44" then @set {alarm} = "TS7 TRA Lost (TS Mode Is IDLE)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:45" then @set {alarm} = "TS7 TRA Lost (TS Mode Is CS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TRXC EC2B:46" then @set {alarm} = "TS7 PCU Lost (TS Mode Is PS)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CON EC1B:8" then @set {alarm} = "LAPD Q CG (LAPD Queue Congestion)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "CON EC2B:8" then @set {alarm} = "LAPD Q CG (LAPD Queue Congestion)"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "RX I1B:0" then @set {alarm} = "RX Internal Amplifier Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:1" then @set {alarm} = "ALNA/TMA Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:3" then @set {alarm} = "RX EEPROM Checksum Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:4" then @set {alarm} = "RX Config Table Checksum Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:5" then @set {alarm} = "RX Synthesizer A/B Unlocked"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:6" then @set {alarm} = "RX Synthesizer C Unlocked"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:7" then @set {alarm} = "RX Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:8" then @set {alarm} = "RX Internal Voltage Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:9" then @set {alarm} = "RX Cable Disconnected"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:10" then @set {alarm} = "RX Initiation Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:11" then @set {alarm} = "CDU Output Voltage Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:12" then @set {alarm} = "TMA-CM Output Voltage Fault"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "RX I1B:14" then @set {alarm} = "CDU Supervision/Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:15" then @set {alarm} = "RX High Temperature"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:17" then @set {alarm} = "TMA Supervision Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:18" then @set {alarm} = "TMA Power Distribution Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:19" then @set {alarm} = "RX Filter Loadfile Checksum Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:20" then @set {alarm} = "RX Cable Supervision Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:21" then @set {alarm} = "Traffic Lost Uplink"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:22" then @set {alarm} = "Antenna System DC Power Supply Overloaded"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:23" then @set {alarm} = "Radio Unit Antenna System Output Voltage Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I1B:47" then @set {alarm} = "RX Auxiliary Equipment Fault"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "RX I2A:0" then @set {alarm} = "CXU Supervision/Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I2A:1" then @set {alarm} = "RX Path Lost on A Receiver Side"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I2A:2" then @set {alarm} = "RX Path Lost on B Receiver Side"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I2A:3" then @set {alarm} = "RX Path Lost on C Receiver Side"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I2A:4" then @set {alarm} = "RX Path Lost on D Receiver Side"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I2A:5" then @set {alarm} = "RX Path A Imbalance"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I2A:6" then @set {alarm} = "RX Path B Imbalance"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I2A:7" then @set {alarm} = "RX Path C Imbalance"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "RX I2A:8" then @set {alarm} = "RX Path D Imbalance"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TF I1A:0" then @set {alarm} = "Temperature Below Operational Limit"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TF I1A:1" then @set {alarm} = "Temperature Above Operational Limit"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "TF I1B:0" then @set {alarm} = "Optional Synchronization Source"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TF I1B:1" then @set {alarm} = "DXU-Opt EEPROM Checksum Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TF I1B:2" then @set {alarm} = "GPS Synch Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TF I2A:0" then @set {alarm} = "Frame Start Offset Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TF EC1B:0" then @set {alarm} = "EXT SYNCH (No Usable External Reference)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TF EC1B:1" then @set {alarm} = "PCM SYNCH (No Usable PCM Reference)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TF EC1B:6" then @set {alarm} = "EXT CFG (Multiple Timing Masters)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TF EC1B:7" then @set {alarm} = "EXT MEAS (ESB Measurement Failure)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TF EC2B:0" then @set {alarm} = "EXT SYNCH (No Usable External Reference)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TF EC2B:1" then @set {alarm} = "PCM SYNCH (No Usable PCM Reference)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TF EC2B:7" then @set {alarm} = "EXT MEAS (ESB Measurement Failure)"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TS EC1B:3" then @set {alarm} = "TRA/PCU (Remote Transcoder/PCU Com. Lost)"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "TX I1A:0" then @set {alarm} = "TX Offending"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1A:1" then @set {alarm} = "Internal HC Load Power Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1A:2" then @set {alarm} = "UC/HC Switch Inconsistent with IDB"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1A:3" then @set {alarm} = "TX RF Power Back Off Failed"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "TX I1B:0" then @set {alarm} = "CU/CDU Not Usable"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:1" then @set {alarm} = "CDU/Combiner VSWR Limits Exceeded"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:2" then @set {alarm} = "CU/CDU Output Power Limits Exceeded"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:4" then @set {alarm} = "TX Antenna VSWR Limits Exceeded"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:6" then @set {alarm} = "TX EEPROM Checksum Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:7" then @set {alarm} = "TX Config Table Checksum Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:8" then @set {alarm} = "TX Synthesizer A/B Unlocked"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:9" then @set {alarm} = "TX Synthesizer C Unlocked"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:10" then @set {alarm} = "TX Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:11" then @set {alarm} = "TX Internal Voltage Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:12" then @set {alarm} = "TX High Temperature"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:13" then @set {alarm} = "TX Output Power Limits Exceeded"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:14" then @set {alarm} = "TX Saturation"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:17" then @set {alarm} = "TX Initiation Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:18" then @set {alarm} = "CU/CDU HW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:19" then @set {alarm} = "CU/CDU SW Load/Start Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:20" then @set {alarm} = "CU/CDU Input Power Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:21" then @set {alarm} = "CU/CDU Park Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:22" then @set {alarm} = "VSWR/Output Power Supervision Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:23" then @set {alarm} = "CU/CDU Reset, Power On"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:24" then @set {alarm} = "CU Reset, Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:25" then @set {alarm} = "CU/CDU Reset, Watchdog"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:26" then @set {alarm} = "CU/CDU Fine Tuning Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:27" then @set {alarm} = "TX Max Power Restricted"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:28" then @set {alarm} = "CDU High Temperature"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "TX I1B:30" then @set {alarm} = "TX CDU Power Control Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:31" then @set {alarm} = "Power Amplifier Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:32" then @set {alarm} = "TX Low Temperature"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:33" then @set {alarm} = "CDU-Bus Communication Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:34" then @set {alarm} = "Y link - XBus Collision Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:35" then @set {alarm} = "RX Path Imbalance"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:36" then @set {alarm} = "Radio Unit HW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:37" then @set {alarm} = "Feeder Connectivity Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I1B:47" then @set {alarm} = "TX Auxiliary Equipment Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I2A:0" then @set {alarm} = "TX Diversity Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I2A:1" then @set {alarm} = "Fast Antenna Hopping Failure"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "TX I2A:2" then @set {alarm} = "TX RF Power Back Off Exceeded"
@ifdef {alarm} then  @goto SALIENDO

@if {PatternToSeek} = "MCTR I1A:0" then @set {alarm} = "Radio Unit Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I1A:1" then @set {alarm} = "HW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I1A:2" then @set {alarm} = "Software Load of Radio Unit Failed"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I1A:3" then @set {alarm} = "HW and IDB Inconsistent"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I1A:4" then @set {alarm} = "Radio Unit in Full Maintenance Mode"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I1B:0" then @set {alarm} = "Radio Unit Connection Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I1B:1" then @set {alarm} = "Temperature Exceptional"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I1B:2" then @set {alarm} = "Lost Communication to Radio Unit"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I1B:3" then @set {alarm} = "Traffic Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I1B:4" then @set {alarm} = "MSMM Synch Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:0" then @set {alarm} = "HW Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:1" then @set {alarm} = "RX Cable Disconnected"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:2" then @set {alarm} = "VSWR Over Threshold"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:4" then @set {alarm} = "Temperature Abnormal"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:5" then @set {alarm} = "RX Maxgain Violated"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:6" then @set {alarm} = "Current to high"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:7" then @set {alarm} = "High Frequency of Software Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:8" then @set {alarm} = "Traffic Lost"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:9" then @set {alarm} = "ALNA/TMA Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:10" then @set {alarm} = "Auxiliary Equipment Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:11" then @set {alarm} = "CPRI Delay Too Long Active Path"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:12" then @set {alarm} = "Communication Disturbance Between Radio"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:13" then @set {alarm} = "Communication Failure Between Radio Units"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:14" then @set {alarm} = "Communication Equipment Fault in Cascade"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:15" then @set {alarm} = "Lost Communication to Radio Unit in Cascade"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:16" then @set {alarm} = "RX Path Lost on A Receiver Side"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:17" then @set {alarm} = "RX Path Lost on B Receiver Side"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:18" then @set {alarm} = "RX Path Lost on C Receiver Side"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:19" then @set {alarm} = "RX Path Lost on D Receiver Side"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:20" then @set {alarm} = "RX Path A Imbalance"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:21" then @set {alarm} = "RX Path B Imbalance"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:22" then @set {alarm} = "RX Path C Imbalance"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:23" then @set {alarm} = "RX Path D Imbalance"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:24" then @set {alarm} = "CPRI Delay Too Long Redundant Path"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:25" then @set {alarm} = "Frequency Bandwidth Mismatch"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:26" then @set {alarm} = "Tx RF Power Back Off Failed"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:27" then @set {alarm} = "Feeder Connectivity Fault"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR I2A:28" then @set {alarm} = "Lost Communication to Radio Unit"
@ifdef {alarm} then  @goto SALIENDO
@if {PatternToSeek} = "MCTR EC1B:10" then @set {alarm} = "CC CONF (Inconsistent Combined Cell Configuration)"
@ifdef {alarm} then  @goto SALIENDO

@set {alarm} = "Oops!. Alarm's comment isn't in our database."
@label SALIENDO
@set {alarm} = {PatternToSeek} + " (" + {alarm} +")"
@label OUTSEEKALARMCOMMENT
@append {FileAlarms} {alarm}
@return



@label SEEKRUCOMMENT
@unset {ru}
@set {PatternToSeek} = {MOshort} + " " + {coderu}

@if {PatternToSeek} = "CF 0" then @set {ru} = "DXU, DUG 10, DUG 20, MU or IXU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 1" then @set {ru} = "ECU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 2" then @set {ru} = "Micro RBS"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 3" then @set {ru} = "Y Link"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 4" then @set {ru} = "TIM"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 5" then @set {ru} = "CDU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 6" then @set {ru} = "CCU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 7" then @set {ru} = "PSU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 8" then @set {ru} = "BFU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 9" then @set {ru} = "BDM"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 10" then @set {ru} = "ACCU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 11" then @set {ru} = "Active Cooler"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 12" then @set {ru} = "ALNA/TMA A"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 13" then @set {ru} = "ALNA/TMA B"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 14" then @set {ru} = "Battery"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 15" then @set {ru} = "Fan / Fan Group"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 16" then @set {ru} = "Heater"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 17" then @set {ru} = "Heat Exchanger Ext Fan"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 18" then @set {ru} = "Heat Exchanger Int Fan"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 19" then @set {ru} = "Humidity Sensor"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 20" then @set {ru} = "TMA-CM"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 21" then @set {ru} = "Temperature Sensor"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 22" then @set {ru} = "CDU HLOUT HLIN Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 23" then @set {ru} = "CDU RX IN Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 24" then @set {ru} = "CU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 25" then @set {ru} = "DU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 26" then @set {ru} = "FU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 27" then @set {ru} = "FU CU PFWD Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 28" then @set {ru} = "FU CU PREFL Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 29" then @set {ru} = "CAB HLIN Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 30" then @set {ru} = "CDU bus"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 31" then @set {ru} = "Environment"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 32" then @set {ru} = "Local Bus"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 33" then @set {ru} = "EPC Bus/Power Communication Loop"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 34" then @set {ru} = "IDB"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 36" then @set {ru} = "Timing Bus"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 37" then @set {ru} = "CDU CXU RXA Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 38" then @set {ru} = "CDU CXU RXB Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 39" then @set {ru} = "X bus"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 40" then @set {ru} = "Antenna"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 41" then @set {ru} = "PSU DC Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 42" then @set {ru} = "CXU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 43" then @set {ru} = "Flash Card"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 45" then @set {ru} = "Battery Temp Sensor"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 46" then @set {ru} = "FCU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 47" then @set {ru} = "TMA-CM Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 48" then @set {ru} = "GPS Receiver"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 49" then @set {ru} = "GPS Receiver DXU Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 50" then @set {ru} = "Active Cooler Fan"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 51" then @set {ru} = "BFU Fuse or Circuit Breaker"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 52" then @set {ru} = "CDU CDU PFWD Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 53" then @set {ru} = "CDU CDU PREFL Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 54" then @set {ru} = "IOM Bus"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 55" then @set {ru} = "ASU RXA Units or Cables"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 56" then @set {ru} = "ASU RXB Units or Cables"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 57" then @set {ru} = "ASU CDU RXA Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 58" then @set {ru} = "ASU CDU RXB Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 59" then @set {ru} = "MCPA"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 60" then @set {ru} = "BSU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 61" then @set {ru} = "PDU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 62" then @set {ru} = "SAU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 63" then @set {ru} = "SCU or SUP"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 64" then @set {ru} = "RUS, RRUS, AIR or mRRUS"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "CF 65" then @set {ru} = "SXU"
@ifdef {ru} then  @goto SALIENDORU


@if {PatternToSeek} = "TRXC 0" then @set {ru} = "TRU, dTRU, DRU, RUG, RRU or DUG 20"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 2" then @set {ru} = "Micro RBS"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 3" then @set {ru} = "CXU TRU RXA Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 4" then @set {ru} = "CXU TRU RXB Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 10" then @set {ru} = "CDU to TRU PFWD Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 11" then @set {ru} = "CDU to TRU PREFL Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 12" then @set {ru} = "CDU to TRU RXA Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 13" then @set {ru} = "CDU to TRU RXB Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 14" then @set {ru} = "CDU to Splitter Cable or Splitter to TRU RXA Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 15" then @set {ru} = "CDU to Splitter Cable or Splitter to TRU RXB Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 16" then @set {ru} = "CDU to TRU TX Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 17" then @set {ru} = "CDU to Splitter Cable or Splitter to CXU RXA Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 18" then @set {ru} = "CDU to Splitter Cable or Splitter to CXU RXB Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 19" then @set {ru} = "Splitter to DRU Cable or DRU to Splitter RXA Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 20" then @set {ru} = "Splitter to DRU Cable or DRU to Splitter RXB Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 21" then @set {ru} = "DRU to DRU RXA Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 22" then @set {ru} = "DRU to DRU RXB Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 23" then @set {ru} = "HCU TRU TX Cable or HCU or CDU HCU TX Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 24" then @set {ru} = "BSU"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 25" then @set {ru} = "RUS, RRUS, AIR or mRRUS"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 26" then @set {ru} = "RUG to RUG RXA Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 27" then @set {ru} = "RUG to RUG RXB Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 28" then @set {ru} = "RUS to RUS RXA Cable"
@ifdef {ru} then  @goto SALIENDORU
@if {PatternToSeek} = "TRXC 29" then @set {ru} = "RUS to RUS RXB Cable"
@ifdef {ru} then  @goto SALIENDORU

@set {ru} = "Oops!. RU comment isn't in our database."
@label SALIENDORU
@set {ru} = {PatternToSeek} + " (" + {ru} +")"
@append {FileAlarms} {ru}
@return