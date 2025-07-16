# Capture.ps1 - Script for capturing the system image using DISM (Clean Root Version)

# Define paths (adjusted for new structure)
$currentStageFile = "$PSScriptRoot/current_stage.json"
$imageSavePath = "D:\_Images"
$enginePath = Join-Path $PSScriptRoot "Engine"

# Check if current_stage.json exists
if (!(Test-Path $currentStageFile)) {
    Write-Host "[ERROR] No current stage selected. Please select a stage using app.ps1." -ForegroundColor Red
    exit
}

# Load the current stage
try {
    $currentStage = Get-Content $currentStageFile | ConvertFrom-Json
    Write-Host "[INFO] Loaded current stage: $($currentStage.Stage)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to load current stage. Error: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Extract WIM file details
$wimFileName = $currentStage.wimFileName
if (-not $wimFileName) {
    Write-Host "[ERROR] WIM file name is missing in current stage. Exiting." -ForegroundColor Red
    exit
}

# Build the full save path
$saveFilePath = Join-Path -Path $imageSavePath -ChildPath "$wimFileName.wim"

# Ensure the save directory exists
if (!(Test-Path $imageSavePath)) {
    Write-Host "[INFO] Creating save directory: $imageSavePath" -ForegroundColor Yellow
    try {
        New-Item -Path $imageSavePath -ItemType Directory -Force | Out-Null
        Write-Host "[SUCCESS] Save directory created successfully" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to create save directory. Error: $($_.Exception.Message)" -ForegroundColor Red
        exit
    }
}

# Locate DISM executable (check multiple locations)
$dismLocations = @(
    Join-Path -Path $enginePath -ChildPath "dism\dism.exe",
    "C:\Windows\System32\dism.exe",
    "dism.exe"
)

$dismPath = $null
foreach ($location in $dismLocations) {
    if (Test-Path $location) {
        $dismPath = $location
        Write-Host "[INFO] Found DISM at: $dismPath" -ForegroundColor Green
        break
    }
}

if (-not $dismPath) {
    Write-Host "[ERROR] DISM executable not found in any of the following locations:" -ForegroundColor Red
    $dismLocations | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    Write-Host "[INFO] Attempting to use system DISM..." -ForegroundColor Yellow
    $dismPath = "dism.exe"  # Try system PATH
}

Write-Host "`n=== YUNA Image Capture Starting ===" -ForegroundColor Cyan
Write-Host "[INFO] Capturing stage: $($currentStage.Stage)" -ForegroundColor White
Write-Host "[INFO] Image type: $($currentStage.ImageType)" -ForegroundColor White
Write-Host "[INFO] Output file: $saveFilePath" -ForegroundColor White
Write-Host "[INFO] DISM location: $dismPath" -ForegroundColor White

# Display capture information
Write-Host "`n=== Capture Details ===" -ForegroundColor Yellow
Write-Host "Source: C:\" -ForegroundColor Gray
Write-Host "Destination: $saveFilePath" -ForegroundColor Gray
Write-Host "Compression: Maximum" -ForegroundColor Gray
Write-Host "Image Name: $($currentStage.Stage)" -ForegroundColor Gray

# Confirm before starting
Write-Host "`n[WARNING] This operation will capture the entire C: drive." -ForegroundColor Yellow
Write-Host "[WARNING] Ensure all applications are closed and system is in desired state." -ForegroundColor Yellow
$confirmation = Read-Host "`nDo you want to continue? (Y/N)"

if ($confirmation -notin @("Y", "y", "Yes", "yes")) {
    Write-Host "[INFO] Capture operation cancelled by user." -ForegroundColor Yellow
    exit
}

Write-Host "`n[INIT] Starting image capture..." -ForegroundColor DarkYellow
Write-Host "[INFO] This may take several minutes depending on system size..." -ForegroundColor Cyan

# Build DISM arguments
$dismArgs = @(
    "/Capture-Image",
    "/ImageFile:`"$saveFilePath`"",
    "/CaptureDir:C:\",
    "/Name:`"$($currentStage.Stage)`"",
    "/Compress:max"
)

# Add description if available
if ($currentStage.wimDescription) {
    $dismArgs += "/Description:`"$($currentStage.wimDescription)`""
}

Write-Host "[DEBUG] DISM Command: $dismPath $($dismArgs -join ' ')" -ForegroundColor Blue

try {
    # Start DISM process with real-time output
    $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processStartInfo.FileName = $dismPath
    $processStartInfo.Arguments = $dismArgs -join ' '
    $processStartInfo.UseShellExecute = $false
    $processStartInfo.RedirectStandardOutput = $true
    $processStartInfo.RedirectStandardError = $true
    $processStartInfo.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processStartInfo
    
    # Event handlers for real-time output
    $process.add_OutputDataReceived({
        param($sender, $e)
        if ($e.Data) {
            Write-Host "[DISM] $($e.Data)" -ForegroundColor Gray
        }
    })
    
    $process.add_ErrorDataReceived({
        param($sender, $e)
        if ($e.Data) {
            Write-Host "[DISM ERROR] $($e.Data)" -ForegroundColor Red
        }
    })
    
    # Start the process
    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()
    
    # Wait for completion
    $process.WaitForExit()
    $exitCode = $process.ExitCode
    
    if ($exitCode -eq 0) {
        Write-Host "`n[SUCCESS] Image capture completed successfully!" -ForegroundColor Green
        
        # Get file information
        if (Test-Path $saveFilePath) {
            $fileInfo = Get-Item $saveFilePath
            $fileSizeGB = [math]::Round($fileInfo.Length / 1GB, 2)
            
            Write-Host "`n=== Capture Summary ===" -ForegroundColor Cyan
            Write-Host "Output File: $saveFilePath" -ForegroundColor White
            Write-Host "File Size: $fileSizeGB GB" -ForegroundColor White
            Write-Host "Created: $($fileInfo.CreationTime)" -ForegroundColor White
            Write-Host "Stage: $($currentStage.Stage)" -ForegroundColor White
            Write-Host "Image Type: $($currentStage.ImageType)" -ForegroundColor White
        }
    } else {
        throw "DISM process failed with exit code: $exitCode"
    }
    
} catch {
    Write-Host "`n[ERROR] Image capture failed!" -ForegroundColor Red
    Write-Host "[ERROR] Details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Delete the current_stage.json file
try {
    Remove-Item -Path $currentStageFile -Force
    Write-Host "[INFO] Removed current stage file: $currentStageFile" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Failed to delete current stage file: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Final success message
Write-Host "`n=== Capture Process Completed Successfully ===" -ForegroundColor Green
Write-Host "Image saved to: $saveFilePath" -ForegroundColor White
Write-Host "You can now deploy this image using standard WIM deployment tools." -ForegroundColor Cyan

Write-Host "`n[INFO] Capture process completed." -ForegroundColor Green