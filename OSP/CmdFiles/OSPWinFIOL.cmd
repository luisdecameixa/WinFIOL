@@ 2G
@clear
@set {site}    = SITE_NAME
@set {BSC}     = BSC_NAME
@set {cell[0]} = CELL_NAME
@set {cell[1]} = *
@set {cell[2]} = *
@set {cell[3]} = *
@include GSMRutinesCell.cmd
@execwait alarms2gdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}
@execwait rxelpdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}

@clear
@set {site}  = SITE_NAME
@set {BSC}   = BSC_NAME
@set {tg[0]} = TG_NUMBER
@set {tg[1]} = *
@set {tg[2]} = *
@set {tg[3]} = *
@set {tg[4]} = *
@include GSMRutinesAlarmsV3.cmd
@execwait alarms2gdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}
@execwait rxelpdecode.bat {_LOGDIR}\{site}.Log2G.{BSC}

@@ 3G MAD
telnet -a xxx.xxx.xxx.xxx
ourpassword
@@ 3G BAD
telnet -a xxx.xxx.xxx.xxx
ourpassword

@clear
@set {site}   = SITE_NAME 
@set {chkrnc} = 1
@include UMTSRutinesOSP.cmd
exit

@@ 4G
telnet -a xxx.xxx.xxx.xxx
ourpassword
@clear
@set {site} = SITE_NAME 
@include LTERutinesOSPV2.cmd
exit
