$wmi = Get-WmiObject -Class Win32_ComputerSystem
$modelName = $wmi.Model.Trim()

$logFile = "C:\Windows\Temp\initializationComplete.log"

IF ($modelName -eq "SIMATIC IPC PX-39A") {
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TipbandDesiredVisibility /T REG_DWORD /D 1 /F
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TouchKeyboardTapInvoke /T REG_DWORD /D 2 /F
	"UIConfig for PX-39A"  | Out-File -Append -FilePath $logFile
}

IF ($modelName -eq "SIMATIC IPC PX-39A PRO") {
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TipbandDesiredVisibility /T REG_DWORD /D 1 /F
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TouchKeyboardTapInvoke /T REG_DWORD /D 2 /F
	"UIConfig for PX-39A PRO"  | Out-File -Append -FilePath $logFile
}
