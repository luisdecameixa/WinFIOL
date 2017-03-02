@G+
! ----------------------------------------------------------------------------
! "THE BEER-WARE LICENSE" (Revision 42):
! <luisdecameixa@coit.es> wrote this file. As long as you retain this notice you
! can do whatever you want with this stuff. If we meet some day, and you think
! this stuff is worth it, you can buy me a beer in return Luis Diaz Gonzalez
! ----------------------------------------------------------------------------
@G-

@param {site}
@param {BSC}
@param {cell}

@R-
@gettime {time}
@getdate {date}
@comment [day {date}] [time {time}]
@trim {BSC}

eaw {BSC}
@gosub GETTGMAIN
exit;
@ifndef {tg[0]} then @exit
@include GSMRutinesAlarmsV3.cmd
@R+
@exit



@label GETTGMAIN
@size {cell} {numcell}
@set {j} = 0
@while {j} < {numcell}
	@trim {cell[{j}]}
	@if {cell[{j}]} = * then @goto nextcell
	rxtcp:moty=rxotg,cell={cell[{j}]};
	@iferror then @goto nextcell
    @merge {lineas} = {_lines}
	@compact {lineas}

	@unset {found}
	@grep {found} {lineas[1]} "NOT ACCEPTED"
	@ifdef {found} then @comment CELLS NOT FOUND NOT ACCEPTED
	@ifdef {found} then @goto nextcell
	@unset {found}
	@grep {found} {lineas[3]} ".*CELL.*"
	@ifndef {found} then @comment CELLS NOT FOUND
	@ifndef {found} then @goto nextcell

	@set {linea} =  {lineas[4]}
	@cut {tgtmp} {linea} col 1
	@after {tg_} {tgtmp} "RXOTG-"
	@comment {tg_}
    @set {tg[{j}]} = {tg_}

@label nextcell
	@inc {j}
@endwhile
@ifndef {tg[0]} then @return
@unique {tg}
@compact {tg}
@return

