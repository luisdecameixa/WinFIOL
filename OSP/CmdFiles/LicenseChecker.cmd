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
@set {OSS4G} = "xxx.xxx.xxx.xxx"
@log on LicensesAlarms.txt

@read "OSPsitesLicenses.txt" {data}
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

@trim {site}

@copy {site} {sitepre} 1 3
@copy {site} {sitenum} 4 4

/opt/ericsson/ddc/util/bin/listme | grep -i '{sitepre}[X-Z]{sitenum}'  | cut -d, -f3 | sed 's/^MeContext=//g' | awk -F@ '{print $1" "$2" "$6" "$7}'
@ifndef {_line1} then @goto 4G
@foreach {_lines} gosub UMTSCHECK


@label 4G
@T 1
telnet -a {OSS4G}
ourpassword
@T 1
@copy {site} {sitepre} 1 3
@copy {site} {sitenum} 4 4

/opt/ericsson/ddc/util/bin/listme | grep '{sitepre}[X-Z]{sitenum}'  | cut -d, -f3 | sed 's/^MeContext=//g' | awk -F@ '{print $1"  "$2"  "$6" "$7}'
@ifndef {_line1} then @goto nextsite
@foreach {_lines} gosub LTECHECK
exit
@T 1

@label nextsite
@inc {i}
@endloop

@label END
@log off
@exit
@R+


@label 3GBAR
@T 1
telnet -a {OSS3GBAR}
ourpassword
@T 1
@goto 3G

@label 3GMAD
@T 1
telnet -a {OSS3GMAD}
ourpassword
@T 1
@goto 3G


@label UMTSCHECK
@if {_curridx} = 0 then @return
@item {IUB} {_currline} " " 0
@unset {amoserror}
@unset {_lines}
amos {IUB}
@grep {amoserror} {_lines} "Checking ip contact...OK"
@ifndef {amoserror} then @goto nextiub
lt all
alt
exit
@label nextiub
@T 1
@return




@label LTECHECK
@if {_curridx} = 0 then @return
@item {eNODE} {_currline} " " 0

@unset {amoserror}
@unset {_lines}
amos {eNODE}
@grep {amoserror} {_lines} "Checking ip contact...OK"
@ifndef {amoserror} then @goto nextenode

lt all
rbs
rbs

alt
exit
@label nextenode
@return