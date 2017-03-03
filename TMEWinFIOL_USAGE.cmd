@@########### 2G ###########

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


@clear
@set {site}  = SITE_NAME                    
@set {BSC}   = BSC_NAME  	 
@set {cell[0]} = CELL_NAME 	 	 	 	 	 
@set {cell[1]} = *  	 
@set {cell[2]} = *
@set {cell[3]} = *
@set {cell[4]} = *
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
@include CRCRutines.cmd



@@########### 3G ###########
@@## MADRID
telnet -l user xxx.xxx.xxx.xxx
yourpassword

@@## BARCELONA
telnet -l user xxx.xxx.xxx.xxx
yourpassword
@set {TCUNameORIP} = "10.34.16.235"
@include TCUPorts&Supervision.cmd 

@clear
@set {site}   = SITE_NAME                              
@set {IUB[0]} = NODE_NAME				
@set {IUB[1]} = * 		
@set {IUB[2]} = *
@set {IUB[3]} = *
@set {IUB[4]} =	*
@set {chkrnc} = 1
@include UMTSRutinesTME.cmd
exit


@@########### 4G ###########
telnet -l user xxx.xxx.xxx.xxx
yourpassword

@set {site}     = SITE_NAME                            
@set {eNODE[0]} = ENODE_NAME
@set {eNODE[1]} = *
@set {eNODE[2]} = *
@set {eNODE[3]} = *
@include LTERutinesTME.cmd
exit

