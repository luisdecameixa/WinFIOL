@ECHO OFF

SET file=%~1

IF "%file%"=="" (
    ECHO %~n0: Usage : alarms2gdecode.bat ^<file^>
    EXIT /B 1
)

IF NOT EXIST "%file%.txt" (
	ECHO %~n0: file not found - %file% >&2
	EXIT /B 1
)

call alarms2g.exe log2g %file%.txt > %file%_alarms2g_decoded.txt