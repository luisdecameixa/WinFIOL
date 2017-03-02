@G+
! ----------------------------------------------------------------------------
! "THE BEER-WARE LICENSE" (Revision 42):
! <luisdecameixa@coit.es> wrote this file. As long as you retain this notice you
! can do whatever you want with this stuff. If we meet some day, and you think
! this stuff is worth it, you can buy me a beer in return Luis Diaz Gonzalez
! ----------------------------------------------------------------------------
@G-


@param {TCUNameORIP}
@trim {TCUNameORIP}
@@L-
@unset {_line1}
/opt/ericsson/ddc/util/bin/listme | grep 'STN.*{TCUNameORIP}@'
@@L+
@ifndef {_line1} then goto FIN
@set {linea} = {_line1}
@ifndef {linea} then goto FIN
@after {IP_} {linea} "@"
@before {IP} {IP_}  "@"

ssh admin@{IP}
yes
hidden
getmoattribute STN=0
getmoattribute STN=0,IPInterface=Synch
getmoattribute STN=0,E1T1Interface=all operationalState
exit

@after {stn_} {linea} ",SubNetwork="
@before {stn} {stn_}  ",MeContext="
@comment {stn}

@after {me_} {linea} "MeContext="
@before {me} {me_}  "@"
@comment {me}

imcmd -select FM_supi SubNetwork=ONRM_RootMo,SubNetwork={stn},ManagedElement={me} -get Alarm_supervision
@label FIN
@end