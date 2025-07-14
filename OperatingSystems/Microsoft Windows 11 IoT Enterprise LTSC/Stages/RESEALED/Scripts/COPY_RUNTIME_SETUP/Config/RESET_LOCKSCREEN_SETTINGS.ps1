# Load required assemblies
Add-Type -AssemblyName System.Runtime.WindowsRuntime
[Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime] | Out-Null

# Remove the LockScreenImage setting from Group Policy registry path
$policyRegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (Test-Path $policyRegistryPath) {
    Remove-Item -Path $policyRegistryPath -Recurse -Force
    Write-Host "Removed Group Policy lock screen settings from $policyRegistryPath."
}

# Remove the LockScreenImagePath and related settings in PersonalizationCSP
$personalizationCSPPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
if (Test-Path $personalizationCSPPath) {
    Remove-Item -Path $personalizationCSPPath -Recurse -Force
    Write-Host "Removed PersonalizationCSP lock screen settings from $personalizationCSPPath."
}

# Load WinRT support
Add-Type -AssemblyName System.Runtime.WindowsRuntime
[Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime] | Out-Null

# Resolve AsTask<T> and AsTask (non-generic) methods
$asTaskGeneric = [System.WindowsRuntimeSystemExtensions].GetMethods() |
    Where-Object { $_.Name -eq "AsTask" -and $_.IsGenericMethodDefinition -and $_.GetParameters().Count -eq 1 } |
    Select-Object -First 1

$asTaskNonGeneric = [System.WindowsRuntimeSystemExtensions].GetMethods() |
    Where-Object { $_.Name -eq "AsTask" -and -not $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 } |
    Select-Object -First 1

# Image path to apply as lock screen
$imagePath = "C:\Windows\Web\SIMATIC\SIMATIC_IPC_Device.jpg"

# Get the WinRT type for StorageFile
$storageFileType = [Type]::GetType("Windows.Storage.StorageFile, Windows, ContentType=WindowsRuntime")

# Get the method info for GetFileFromPathAsync
$getFileMethod = $storageFileType.GetMethod("GetFileFromPathAsync")

# Invoke GetFileFromPathAsync
$storageFileOp = $getFileMethod.Invoke($null, @($imagePath))

# Await result using AsTask<T>
$asTaskFile = $asTaskGeneric.MakeGenericMethod($storageFileType)
$storageFile = $asTaskFile.Invoke($null, @($storageFileOp)).Result

# Set lock screen image
$setImageOp = [Windows.System.UserProfile.LockScreen]::SetImageFileAsync($storageFile)
$asTaskNonGeneric.Invoke($null, @($setImageOp)).Wait()

Write-Host "Lock screen image set successfully!" -ForegroundColor Green
