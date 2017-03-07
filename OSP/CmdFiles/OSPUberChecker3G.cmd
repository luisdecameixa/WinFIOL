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
@read "OSPsites.txt" {data}
@size {data} {linecount}

@set {i} = 0
@loop {linecount}
@item {site} {data[{i}]} "-" 0

@if {site} = "ENDFILE" then @goto END

@item {zona} {data[{i}]} "-" 1

@@ 3G
@if {zona} = "B" then @goto 3GBAR
@if {zona} <> "B" then @goto 3GMAD

@label 3G
@set {chkrnc}= 1
@include UMTSRutinesOSP.cmd
exit
@T 2


@inc {i}
@endloop

@label END
@exit
@R+


@label 3GBAR
@T 2
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