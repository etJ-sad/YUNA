
# Capture.ps1 - Script for capturing the system image using DISM

# Define paths
$currentStageFile = "$PSScriptRoot/current_stage.json"
$imageSavePath = "D:\_Images"

# Check if current_stage.json exists
if (!(Test-Path $currentStageFile)) {
    Write-Host "[ERROR] No current stage selected. Please select a stage using app.ps1."
    exit
}

# Load the current stage
try {
    $currentStage = Get-Content $currentStageFile | ConvertFrom-Json
    Write-Host "[INFO] Loaded current stage: $($currentStage.Stage)"
} catch {
    Write-Host "[ERROR] Failed to load current stage. Error: $($_.Exception.Message)"
    exit
}

# Extract WIM file details
$wimFileName = $currentStage.wimFileName
if (-not $wimFileName) {
    Write-Host "[ERROR] WIM file name is missing in current stage. Exiting."
    exit
}

# Build the full save path
$saveFilePath = Join-Path -Path $imageSavePath -ChildPath "$wimFileName.wim"

# Ensure the save directory exists
if (!(Test-Path $imageSavePath)) {
    Write-Host "[INFO] Creating save directory: $imageSavePath"
    New-Item -Path $imageSavePath -ItemType Directory | Out-Null
}

# Capture the image using DISM
$dismPath = Join-Path -Path "$PSScriptRoot/engine/dism" -ChildPath "dism.exe"
if (!(Test-Path $dismPath)) {
    Write-Host "[ERROR] DISM executable not found at: $dismPath"
    exit
}

Write-Host "[INIT] Starting image capture..."
Write-Host "[INFO] Capturing stage: $($currentStage.Stage)"
Write-Host "[INFO] Saving image to: $saveFilePath"

try {
    Start-Process -FilePath $dismPath -ArgumentList "/Capture-Image", "/ImageFile:$saveFilePath", "/CaptureDir:C:\", "/Name:$($currentStage.Stage)", "/Compress:max" -Wait -NoNewWindow
    Write-Host "[OK] Image capture completed successfully."
} catch {
    Write-Host "[ERROR] Image capture failed. Error: $($_.Exception.Message)"
    exit
}

# Delete the current_stage.json file
try {
    Remove-Item -Path $currentStageFile -Force
    Write-Host "[INFO] Removed current stage file: $currentStageFile"
} catch {
    Write-Host "[ERROR] Failed to delete current stage file. Error: $($_.Exception.Message)"
}

Write-Host "[INFO] Capture process completed."
