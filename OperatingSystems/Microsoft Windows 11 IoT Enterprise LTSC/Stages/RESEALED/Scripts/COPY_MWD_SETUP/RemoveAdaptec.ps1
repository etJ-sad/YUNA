$app = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*MaxView Storage Manager*" }
if ($app) {
    Invoke-CimMethod -InputObject $app -MethodName Uninstall
}
