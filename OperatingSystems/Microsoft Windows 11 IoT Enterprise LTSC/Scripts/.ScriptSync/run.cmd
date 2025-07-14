@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL ENABLEEXTENSIONS

GOTO INIT

:RUNTIME 
	%~d0
	CD %~p0
	
	Set Debug=OFF
	
	IF [%1]==[] (
		powershell -ep Bypass %~dp0\init.ps1 %Debug%
	) ELSE (
		powershell -ep Bypass %1 %Debug%
	)
	
	GOTO EXIT_POINT

:INIT
	%~d0
	CD %~p0
	
   	IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
		>NUL 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\Config\System"
	) ELSE (
		>NUL 2>&1 "%SYSTEMROOT%\System32\cacls.exe" "%SYSTEMROOT%\System32\Config\System"
	)
	
	IF '%ERRORLEVEL%' NEQ '0' (
		GOTO UACPROMT
	) ELSE ( 
		GOTO RUNTIME 
	)

	GOTO EXIT_POINT

:UACPROMT
	ECHO SET UAC = CreateObject^("Shell.Application"^) > "%TEMP%\GET_ADMIN.vbs"
	SET PARAMS= %*
	
	ECHO UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %PARAMS:"=""%", "", "runas", 1 >> "%TEMP%\GET_ADMIN.vbs"
	"%TEMP%\GET_ADMIN.vbs"
	
	DEL "%TEMP%\GET_ADMIN.vbs"
	EXIT /B
	
	GOTO EXIT_POINT

:EXIT_POINT
	GOTO:EOF