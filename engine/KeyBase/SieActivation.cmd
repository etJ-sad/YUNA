@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL ENABLEEXTENSIONS

GOTO INIT

:INIT
	%~d0
	CD %~dp0
	
	IF EXIST ..\settings.cmd CALL ..\settings.cmd check
	SET RSlui=false
	SET XrmmsFile=false
	SET SeCpky=false
	SET delpkea=false

	IF NOT "%WinVer%"=="" GOTO %WinVer%%WinSubVer%
	
	CLS
	
	ECHO.
	ECHO  Activation for...
	ECHO.
	ECHO   1= Windows 10 Enterprise
	ECHO.
	ECHO   2= Windows 11 Enterprise
	ECHO.
	ECHO   3= Windows Server 2016 Standard
	ECHO.
	ECHO   4= Windows Server 2019 Standard
	ECHO.
	ECHO   5= Windows Server 2022 Standard
	ECHO.
	ECHO   6= Windows Server 2025 Standard
	ECHO.
	ECHO   7= Windows Server 2025 Datacenter
	ECHO.	
	SET /p EinG= Please enter number: 
	
	IF "%EinG%"=="1" GOTO W10
	IF "%EinG%"=="2" GOTO W11
	IF "%EinG%"=="3" GOTO W2k16STA
	IF "%EinG%"=="4" GOTO W2k19STA
	IF "%EinG%"=="5" GOTO W2k22STA
	IF "%EinG%"=="6" GOTO W2k25STA
	IF "%EinG%"=="7" GOTO W2k25DTC	
	
	GOTO EXIT_POINT

:W2k16STA
	SET ProgKey=3FYBC-W8NVT-P66XW-KTQT6-BP3DW
	SET XrmmsFile=SIEMENS AG   - 100055.xrm-ms
	SET RSlui=false
	SET SeCpky=false
	
	GOTO PROG

:W2k19STA
	SET ProgKey=3KNXD-4BR7W-QM77W-6RW96-CG3D7
	SET XrmmsFile=SIEMENS AG   - 100055.xrm-ms
	SET RSlui=false
	SET SeCpky=false
	
	GOTO PROG

:W2k22STA
	SET ProgKey=22BT9-NVM7X-QJXPH-DD6BB-TX2X4
	SET XrmmsFile=SIEMENS AG   - 100055.xrm-ms
	SET RSlui=false
	SET SeCpky=false
	
	GOTO PROG
	
:W2k25STA
	SET ProgKey=87T9D-GNGQP-38678-TRCM9-CDQK8
	SET XrmmsFile=SIEMENS AG   - 100055.xrm-ms
	SET RSlui=false
	SET SeCpky=false
	
	GOTO PROG
	
:W2k25DTC
	SET ProgKey=262JN-P64XY-8XDCY-9YJ6H-PWJ3B
	SET XrmmsFile=SIEMENS AG   - 100055.xrm-ms
	SET RSlui=false
	SET SeCpky=false
	
	GOTO PROG	

:W10
:W10LTSB2015
:W10LTSB2016
:W10LTSC2019
:W10LTSC2021
:W11
:GAC
:W11GAC
:W11LTSC2024
	SET ProgKey=false
	IF NOT "%1"=="" SET ProgKey=%1
	if "%1"=="clean" SET ProgKey=false
	if "%1"=="clean" SET delpkea=true
	SET XrmmsFile=false
	SET RSlui=false
	SET SeCpky=true
	
	GOTO PROG

:CheckKey
	CLS
	SET EinG=0
	if "%SERVPATH%"=="" GOTO TypeKey
	ECHO.
	ECHO  The Embedded PKEA is 
	ECHO  "%ProgKey%"
	ECHO.
	ECHO   1= YES
	ECHO.
	ECHO   2= NO
	ECHO.
	SET /p EinG= Is this correct? 
	IF "%EinG%"=="1" GOTO PROG
	:TypeKey
	CLS
	ECHO.
	ECHO  Please type the Embedded PKEA
	ECHO.
	SET /p ProgKey=  KEY: 
	
	GOTO CheckKey
	
	GOTO:EOF

:PROG
	%~d0
	CD %~dp0
	SET LW=%~d0
	IF NOT "%XrmmsFile%"=="false" cmd.exe /c cscript %windir%\system32\slmgr.vbs -ilc "%LW%%XrmmsFile%"
	IF NOT "%ProgKey%"=="false" cmd.exe /c cscript %windir%\system32\slmgr.vbs -ipk %ProgKey%
	if "%RSlui%"=="true" slui.exe
	IF NOT "%SeCpky%"=="true" GOTO jmp_cpky
	cmd.exe /c cscript %windir%\system32\slmgr.vbs -cpky

:jmp_cpky
	

:EXIT_POINT
	SET LW=
	SET EinG=
	SET ProgKey=
	SET XrmmsFile=