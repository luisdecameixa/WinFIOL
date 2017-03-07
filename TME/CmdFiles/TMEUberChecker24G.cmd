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

@if {BSC} = "#" then @goto 4G

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
@T 1
@include GSMRutinesCell.cmd
@execwait alarms2gdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}
@execwait rxelpdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}
exit


@@ 4G
@label 4G
@T 1
telnet -l user {OSS4G}
password
@T 1
@inc {i}
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
@T 1

@label NEXT
@inc {i}
@endloop

@label END
@exit
@R+