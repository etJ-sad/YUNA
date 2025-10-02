# Remove Display and Network adapters and let Windows reinstall with best drivers
Write-Host "=== Removing Display Adapters ===" -ForegroundColor Yellow
Get-PnpDevice -Class Display | ForEach-Object {
    $instanceId = $_.InstanceId
    Write-Host "Removing: $($_.FriendlyName)" -ForegroundColor Yellow
    pnputil /remove-device $instanceId
}

Write-Host "`n=== Removing Network Adapters ===" -ForegroundColor Yellow
Get-PnpDevice -Class Net | ForEach-Object {
    $instanceId = $_.InstanceId
    Write-Host "Removing: $($_.FriendlyName)" -ForegroundColor Yellow
    pnputil /remove-device $instanceId
}

# Rescan for hardware - Windows will pick the best available driver
Write-Host "`n=== Rescanning for hardware ===" -ForegroundColor Cyan
pnputil /scan-devices

# Force install all drivers from DriverStore
Write-Host "`n=== Installing drivers from DriverStore ===" -ForegroundColor Green
Get-ChildItem "C:\Windows\System32\DriverStore\FileRepository\" -Recurse -Filter "*.inf" | ForEach-Object {
    Write-Host "Installing: $($_.Name)" -ForegroundColor Green
    pnputil /add-driver $_.FullName /install
}
