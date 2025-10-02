$wmi = Get-WmiObject -Class Win32_ComputerSystem
$modelName = $wmi.Model.Trim()

$logFile = "C:\Windows\Temp\initializationComplete.log"

IF ($modelName -eq "SIMATIC IPC PX-39A") {
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TipbandDesiredVisibility /T REG_DWORD /D 1 /F
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TouchKeyboardTapInvoke /T REG_DWORD /D 2 /F
	"Virtual Keyboard icon enabled on SIMATIC IPC PX-39A"  | Out-File -Append -FilePath $logFile
}

IF ($modelName -eq "SIMATIC IPC PX-39A PRO") {
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TipbandDesiredVisibility /T REG_DWORD /D 1 /F
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TouchKeyboardTapInvoke /T REG_DWORD /D 2 /F
	"Virtual Keyboard icon enabled on SIMATIC IPC PX-39A PRO"  | Out-File -Append -FilePath $logFile
}

IF ($modelName -eq "SIMATIC IPC 677E") {
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TipbandDesiredVisibility /T REG_DWORD /D 1 /F
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TouchKeyboardTapInvoke /T REG_DWORD /D 2 /F
	"Virtual Keyboard icon enabled on SIMATIC IPC 677E"  | Out-File -Append -FilePath $logFile
}

IF ($modelName -eq "SIMATIC IPC677E") {
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TipbandDesiredVisibility /T REG_DWORD /D 1 /F
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TouchKeyboardTapInvoke /T REG_DWORD /D 2 /F
	"Virtual Keyboard icon enabled on SIMATIC IPC677E"  | Out-File -Append -FilePath $logFile
}

IF ($modelName -eq "SIMATIC IPC PX-32A") {
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TipbandDesiredVisibility /T REG_DWORD /D 1 /F
	REG ADD "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /V TouchKeyboardTapInvoke /T REG_DWORD /D 2 /F
	"Virtual Keyboard icon enabled on SIMATIC IPC PX-32A"  | Out-File -Append -FilePath $logFile
}