@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL ENABLEEXTENSIONS

GOTO INIT

:INIT
	%~d0
	CD %~p0

::YUNONA
	IF EXIST C:\Users\Public\Yunona\yunona.ps1 powershell -ep Bypass .\deviceReinit.ps1 >NUL 2>NUL 
	
::PATCH
	IF EXIST %~dp0_patch.zip powershell -command "Expand-Archive -Force '%~dp0_patch.zip' '%~dp0'" >NUL 2 >NUL
	IF EXIST %SystemRoot%\Setup\Scripts\Siemens\_applyPatch.cmd CALL C:\Windows\Setup\Scripts\Siemens\_applyPatch.cmd >NUL 2 >NUL
	
::RECOVERY IMAGE
	IF EXIST C:\Windows\Panther\SIEMENS_RECOVERY_IMAGE GOTO RECOVERY_IMAGE	
	
::IMAGE REFRESH
	IF EXIST %SystemRoot%\Setup\Scripts\Siemens\ReFresh\MakeReFresh.cmd CALL %SystemRoot%\Setup\Scripts\Siemens\ReFresh\MakeReFresh.cmd
	
::ENABLE SYSTEM PROTECTION
	powershell -ep Bypass .\EnableSystemProtection.ps1 >NUL 2>NUL

::REMOVE ALL HIDDEN DEVICES
	powershell -ep Bypass .\REMOVE_ALL_HIDDEN_DEVICES.ps1 -Force >NUL 2>NUL
	
::SET_WALLPAPER_FILL
	REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v WallpaperStyle /t REG_SZ /d 4 /f
		
::DEVICE_SPECIFIC_SETTINGS
	IF EXIST %SystemRoot%\Setup\Scripts\Siemens\DeviceSpecificSettings.ps1 powershell -ep Bypass .\DeviceSpecificSettings.ps1 >NUL 2>NUL
		
::NVIDIA	
	SET NVIDIA="VEN_10DE"
	"%~dp0DeviceFinder.exe" %NVIDIA%
	IF %ERRORLEVEL%==1 ECHO Nvidia are installed on this SIMATIC device > NVIDIA_INSTALLED
	::REMOVE_IF_NOT_INSTALLED
	IF NOT EXIST %SystemRoot%\Setup\Scripts\Siemens\NVIDIA_INSTALLED powershell -ep Bypass .\RemoveNvidia.ps1 >NUL 2>NUL
	
::ADAPTEC
	SET ADAPTEC_ID="VEN_9005"
	"%~dp0DeviceFinder.exe" %ADAPTEC_ID%
	IF %ERRORLEVEL%==1 ECHO Adaptec are installed on this SIMATIC device > ADAPTEC_INSTALLED
	::REMOVE_IF_NOT_INSTALLED
	IF NOT EXIST %SystemRoot%\Setup\Scripts\Siemens\ADAPTEC_INSTALLED powershell -ep Bypass .\RemoveAdaptec.ps1 >NUL 2>NUL

::BROADCOM
	SET BROADCOM_ID="VEN_1000"
	"%~dp0DeviceFinder.exe" %BROADCOM_ID%
	IF %ERRORLEVEL%==1 ECHO Broadcom are installed on this SIMATIC device > BROADCOM_INSTALLED
	::REMOVE_IF_NOT_INSTALLED
	IF NOT EXIST %SystemRoot%\Setup\Scripts\Siemens\BROADCOM_INSTALLED powershell -ep Bypass .\RemoveBroadcom.ps1 >NUL 2>NUL
	
	GOTO EXIT_POINT

:RECOVERY_IMAGE
	powershell -ep Bypass .\SiemensValidate.ps1 >NUL 2>NUL

	GOTO EXIT_POINT
	
:EXIT_POINT
	GOTO:EOF