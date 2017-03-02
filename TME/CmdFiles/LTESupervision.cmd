@G+
! ----------------------------------------------------------------------------
! "THE BEER-WARE LICENSE" (Revision 42):
! <luisdecameixa@coit.es> wrote this file. As long as you retain this notice you
! can do whatever you want with this stuff. If we meet some day, and you think
! this stuff is worth it, you can buy me a beer in return Luis Diaz Gonzalez
! ----------------------------------------------------------------------------
@G-


@param {eNode_}
@trim {eNode_}
@L-
@unset {_line1}
/opt/ericsson/ddc/util/bin/listme | grep {eNode_} | cut -d, -f2 | sed 's/^SubNetwork=//g'
@L+
@ifndef {_line1} then goto FIN
@set {sn} = {_line1}
@comment {sn}

imcmd -select FM_supi SubNetwork=ONRM_ROOT_MO,SubNetwork={sn},MeContext={eNode_} -get Alarm_supervision
@L-
@@end