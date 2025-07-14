$PackageName = Get-AppxPackage | Where-Object { $_.Name -like 'NVIDIA*' }

Remove-AppPackage -Package $PackageName -AllUsers

Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\NVIDIA Corporation" -Recurse 

$us = Get-childItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object {$_.DisplayName -like "*NVIDIA Graphics Driver*"} | select DisplayName, UninstallString

$unused, $filePath, $argList = $us.UninstallString -split '"', 3

$argList += ' -silent -deviceinitiated'

Start-Process -FilePath "C:\Windows\SysWOW64\RunDll32.EXE" -ArgumentList $argList -Wait

Remove-Item -Path "C:\Program Files\NVIDIA Corporation" -Recurse 