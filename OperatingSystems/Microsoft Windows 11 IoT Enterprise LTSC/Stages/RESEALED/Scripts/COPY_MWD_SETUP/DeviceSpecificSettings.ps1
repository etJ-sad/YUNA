<#  DeviceSpecificSettings.ps1  #>

# Ensure this script (and any child PowerShell processes) run even under a restricted policy
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Folder that holds the Siemens sub-scripts
$root = Join-Path $env:SystemRoot 'Setup\Scripts\Siemens'

# List the *.ps1 files you want to chain
$scripts = @(
    'xX-32A.ps1',
    'PX-39A.ps1',
    'RC-545A.ps1'
)

foreach ($name in $scripts) {
    $path = Join-Path $root $name
    if (Test-Path $path) {
        & powershell -ExecutionPolicy Bypass -File $path *> $null
    }
}
