$appName = (Get-Package | Where-Object { $_.Name -like "*MaxView Storage Manager*" }).Name
if ($appName) {
    Uninstall-Package -Name $appName -Force
}
