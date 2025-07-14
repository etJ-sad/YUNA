$configOptions = (Get-CimInstance -ClassName Win32_BaseBoard | Select-Object -ExpandProperty ConfigOptions)

Write-Host $configOptions

if ($configOptions -like "*LTSC*"){
	Write-Host "LTSC EXIST" 
} else {
    slmgr /upk
	slmgr /cpky	
}
