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
@read "TMEsites.txt" {data}
@size {data} {linecount}

@set {i} = 0
@loop {linecount}

@set {site} = {data[{i}]}
@if {site} = "ENDFILE" then @goto END

@inc {i}
@set {zona} = {data[{i}]}

@inc {i}
@item {BSC} {data[{i}]} "@" 0

@if {BSC} = "#" then @goto 3GJUMP

@unset {cell}
@item {celltmp} {data[{i}]} "@" 1
@trim {celltmp}
@set {j} = 0
@while {celltmp} <> "#"
	@set {cell[{j}]} = {celltmp}
	@inc {j}
	@calc {col} = {j} + 1
	@item {celltmp} {data[{i}]} "@" {col}
@endwhile
@T 1
telnet -l user {OSS2G}
password
@include GSMRutinesCell.cmd
@execwait alarms2gdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}
@execwait rxelpdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}
exit


@@ 3G
@label 3GJUMP

@if {zona} = "B" then @goto 3GBAR
@if {zona} <> "B" then @goto 3GMAD

@label 3G
@inc {i}

@unset {IUB}
@item {IUBtmp} {data[{i}]} "@" 0
@trim {IUBtmp}
@if {IUBtmp} = "#" then @goto 4G
@set {j} = 0
@while {IUBtmp} <> "#"
	@set {IUB[{j}]} = {IUBtmp}
	@inc {j}
	@item {IUBtmp} {data[{i}]} "@" {j}
@endwhile
@set {chkrnc}= 1
@include UMTSRutinesTME.cmd
exit
@T 2

@@ 4G
@label 4G
@T 2
telnet -l user {OSS4G}
password
@T 2
@inc {i}

@unset {eNODE}
@item {eNODEtmp} {data[{i}]} "@" 0
@trim {eNODEtmp}
@if {eNODEtmp} = "#" then @goto NEXT
@set {j} = 0
@while {eNODEtmp} <> "#"
	@set {eNODE[{j}]} = {eNODEtmp}

	@inc {j}
	@item {eNODEtmp} {data[{i}]} "@" {j}
@endwhile
@include LTERutinesTME.cmd
exit
@T 2

@label NEXT
@inc {i}
@endloop

@label END
@exit
@R+


@label 3GBAR
@T 2
telnet -l user {OSS3GBAR}
password
@T 2
@goto 3G

@label 3GMAD
@T 2
telnet -l user {OSS3GMAD}
password
@T 2
@goto 3G