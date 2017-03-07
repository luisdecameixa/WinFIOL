@G+
! ----------------------------------------------------------------------------
! "THE BEER-WARE LICENSE" (Revision 42):
! <luisdecameixa@coit.es> wrote this file. As long as you retain this notice you
! can do whatever you want with this stuff. If we meet some day, and you think
! this stuff is worth it, you can buy me a beer in return Luis Diaz Gonzalez
! ----------------------------------------------------------------------------
@G-

@R-
@set {OSS3GBAR} = "xxx.xxx.xxx.xxx"
@set {OSS3GMAD} = "xxx.xxx.xxx.xxx"
@read "TMEsites.txt" {data}
@size {data} {linecount}

@set {i} = 0
@loop {linecount}

@set {site} = {data[{i}]}
@if {site} = "ENDFILE" then @goto END

@inc {i}
@set {zona} = {data[{i}]}

@inc {i}
@@ 3G

@if {zona} = "B" then @goto 3GBAR
@if {zona} <> "B" then @goto 3GMAD

@label 3G
@inc {i}

@unset {IUB}
@item {IUBtmp} {data[{i}]} "@" 0
@trim {IUBtmp}
@if {IUBtmp} = "#" then @goto NEXT
@set {j} = 0
@while {IUBtmp} <> "#"
	@set {IUB[{j}]} = {IUBtmp}
	@inc {j}
	@item {IUBtmp} {data[{i}]} "@" {j}
@endwhile
@set {chkrnc}= 1
@include UMTSRutinesTME.cmd
exit
@T 1

@label NEXT
@inc {i}
@inc {i}
@endloop

@label END
@exit
@R+


@label 3GBAR
@T 1
telnet -l user {OSS3GBAR}
password
@T 1
@goto 3G

@label 3GMAD
@T 1
telnet -l user {OSS3GMAD}
password
@T 1
@goto 3G