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
@comment [day {date}] [time {time}]
@trim {BSC}
@trim {site}
@if {site} = * then @set {site} = {BSC} 
@log on {site}.LogCRC.{BSC}.txt
eaw {BSC}
@gosub CHECKTG
@gosub SHOWCRC
exit;
@log off
@R+
@exit

@label SHOWCRC
@size {tg} {numtg}
@set {j} = 0
@comment =====================================
@comment ************ SUMMARY ****************
@comment site {site}
@comment BSC {BSC}
@while {j} < {numtg}
    	@if {tg[{j}]} <> * then @comment TG = {tg[{j}]}  RBS {nmodel[{j}]}  CRC = {crc[{j}]}
		@inc {j}
@endwhile
@comment =====================================
@return


@label CHECKTG
@size {tg} {numtg}
@set {j} = 0
@while {j} < {numtg}
	@trim {tg[{j}]}
	@if {tg[{j}]} <> * then @gosub RutinaCRC
	@inc {j}
@endwhile
@return

@label RutinaCRC
@gosub GETRBSMODEL
@gosub GETDEVSNTCRC
@return


@label GETRBSMODEL
@set {nmodel[{j}]} = 0
@set {tgerror} = 0
@set {GeneralError}=0
rxmfp:mo=rxocf-{tg[{j}]};
@iferror then @set {tgerror} = 1
@if {tgerror}=1 then @set {crc[{j}]} = "Wrong TG"
@if {tgerror}=1 then @return

@ritem {tmp1} {_lines[5]} " " 0
@item {tmp2} {_lines[5]} " " 0
@if {tmp1}={tmp2} then @set {GeneralError} = 1
@if {GeneralError}=1 then @set {nmodel[{j}]} = "ERROR"
@if {GeneralError}=1 then @set {crc[{j}]} = "ERROR"
@if {GeneralError}=1 then @return

@unset {found}
@grep {found} {_lines} ".*CABI [RBS|SUP].+"
@ifndef {found} then @grep {found} {_lines} ".*CABI .+"
@ifndef {found} then @return
@ritem {nmodel_} {found} " " 1
@set {nmodel[{j}]} = {nmodel_}
@return

@label GETDEVSNTCRC
@if {GeneralError}=1 then @return
@if {tgerror}=1 then @return
@set {crcipflag} = 0
rxapp:mo=rxotg-{tg[{j}]};
@if {_LINE3} = "COMMAND NOT VALID FOR CURRENT TG TRANSMISSION MODE" then @set {crcipflag} = 1
@if {crcipflag} = 1 then @set {crc[{j}]}="IP"
@if {crcipflag} = 1 then @return
@unset {found}
@grep {found} {_lines} ".*CF.*"
@comment {found}
@cut {dev} {found} col 1
@after {ndev} {dev} "-"
@before {tmp} {dev} "-"
@@ @comment {tmp}

radep:dev={dev};
@merge {lineas} = {_lines}
@compact {lineas}
@set {linea} =  {lineas[3]}
@cut {snt} {linea} col 2

ntcop:snt={snt};
@merge {lineas} = {_lines}
@compact {lineas}

@set {i} = 2
@label BUCLE
@inc {i}
@unset {linea}
@set {linea} =  {lineas[{i}]}
@ritem {min} {linea} "-&" 1
@ritem {max_} {linea} "&-" 0
@cut {max} {max_} col 1

@if {ndev} < {min} then @goto BUCLE
@if {ndev} > {max} then @goto BUCLE

@@ @comment {linea}
@set {d} = {tmp} + "-" + {min} + "&&-" + {max}
@@ @comment D {d}
@before {dip_} {linea} {d}
@ritem {dip} {dip_} " " 0
@@ @comment DIP {dip}
dtidp:dip={dip};
@copy {_lines[4]} {crc_} 38 38
@cut {crc__} {crc_} col 1
@set {crc[{j}]} = {crc__}
@comment TG = {tg[{j}]}  CRC = {crc[{j}]}
@comment RBS {nmodel[{j}]}
@return
