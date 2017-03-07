@G+
! ----------------------------------------------------------------------------
! "THE BEER-WARE LICENSE" (Revision 42):
! <luisdecameixa@coit.es> wrote this file. As long as you retain this notice you
! can do whatever you want with this stuff. If we meet some day, and you think
! this stuff is worth it, you can buy me a beer in return Luis Diaz Gonzalez
! ----------------------------------------------------------------------------
@G-

@R-
@set {OSS2G} = "xxx.xxx.xxx.xxx"
@set {OSS3GBAR} = "xxx.xxx.xxx.xxx"
@set {OSS3GMAD} = "xxx.xxx.xxx.xxx"
@set {OSS4G} = "xxx.xxx.xxx.xxx"
@read "OSPsites.txt" {data}
@size {data} {linecount}

@set {i} = 0
@loop {linecount}
@item {site} {data[{i}]} "-" 0

@if {site} = "ENDFILE" then @goto END

@item {zona} {data[{i}]} "-" 1
@item {BSC}  {data[{i}]} "-" 2

@if {BSC} = "#" then @goto 3G_

@unset {tg}
@item {tgtmp} {data[{i}]} "-" 3
@trim {tgtmp}
@set {j} = 0
@while {tgtmp} <> "#"
	@set {tg[{j}]} = {tgtmp}

	@inc {j}
	@calc {col} = {j} + 3
	@item {tgtmp} {data[{i}]} "-" {col}
@endwhile
telnet -a {OSS2G}
ourpassword
@T 2
@include GSMRutinesAlarmsV3.cmd
@execwait alarms2gdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}
@execwait rxelpdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}
exit
@T 2

@@ 3G
@label 3G_

@if {zona} = "B" then @goto 3GBAR
@if {zona} <> "B" then @goto 3GMAD

@label 3G
@set {chkrnc}= 1
@include UMTSRutinesOSP.cmd
exit
@T 2

@@ 4G
@T 2
telnet -a {OSS4G}
ourpassword
@T 2
@include LTERutinesOSPV2.cmd
exit
@T 2

@inc {i}
@endloop

@label END
@exit
@R+


@label 3GBAR
@T 1
telnet -a {OSS3GBAR}
ourpassword
@T 2
@goto 3G

@label 3GMAD
@T 2
telnet -a {OSS3GMAD}
ourpassword
@T 2
@goto 3G