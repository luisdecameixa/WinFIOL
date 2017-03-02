@ECHO OFF

SET file=%~1

IF "%file%"=="" (
    ECHO %~n0: Usage : rxelpdecode.bat ^<file^>
    EXIT /B 1
)

IF NOT EXIST "%file%.txt" (
	ECHO %~n0: file not found - %file% >&2
	EXIT /B 1
)

call alarms2g.exe rxelplog2g 0 %file%.txt > %file%_rxelp_decoded.txt