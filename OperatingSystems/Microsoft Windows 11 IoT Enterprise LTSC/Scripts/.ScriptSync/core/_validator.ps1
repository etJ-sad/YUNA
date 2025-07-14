Param([string]$InputFile)

# Version of the validator tool
$validatorVersion = "1.6.0.0"

# Load Windows Forms and Compression assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Function to open a file picker dialog for selecting a JSON file
function Get-JsonFilePath {
    $openFileDialog = [System.Windows.Forms.OpenFileDialog]::new()
    $openFileDialog.Filter = "JSON Files (*.json)|*.json"

    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $openFileDialog.FileName
    } else {
        return $null
    }
}

# Display banner
Write-Host "`n----------------------------------------------------------------" 
Write-Host "  Validator version: $validatorVersion"
Write-Host "----------------------------------------------------------------`n"

# Load the baseline JSON file (either via parameter or file picker)
if (!$InputFile) {
    $deviceMaskValidationFile = Get-ChildItem .\_validation\*deviceMask*.* | Select-Object -First 1
    if ($deviceMaskValidationFile) {
        Write-Host "`n----------------------------------------------------------------"
        Write-Host "  Device configuration mask successfully loaded from: "
        Write-Host "  $($deviceMaskValidationFile.FullName)"
        Write-Host "----------------------------------------------------------------`n"
        $baselineJSON = $deviceMaskValidationFile.FullName
    } else {
        Write-Host "`n----------------------------------------------------------------"   
        Write-Host "  Please manually select the validate file for device mask."
        Write-Host "----------------------------------------------------------------`n"
        $baselineJSON = Get-JsonFilePath
    }
} else {
    Write-Host "`n----------------------------------------------------------------"
    Write-Host "  Device configuration mask successfully loaded from: "
    Write-Host "  $InputFile  "
    Write-Host "----------------------------------------------------------------`n"
    $baselineJSON = $InputFile
}

# Try to load and parse the JSON file
try {
    $baselineJSON = Get-Content -Path $baselineJSON -Raw | ConvertFrom-Json
    Write-Host "`n----------------------------------------------------------------"
    Write-Host "  JSON Data Successfully Imported and Ready for Processing"
    Write-Host "----------------------------------------------------------------`n"
} catch {
    Write-Host "`n----------------------------------------------------------------"
    Write-Error "  Error encountered while reading or parsing the JSON file." 
    Write-Error "  Error details: $($_.Exception.Message)"
    Write-Host "----------------------------------------------------------------`n"
    Read-Host
    exit
}

# Load the auto-validation data
$_autovalidation = Get-Content '.\output\_autovalidation.json' | ConvertFrom-Json

# Compare baseline and validation data by key properties
$comparisonResult = Compare-Object -ReferenceObject $_autovalidation -DifferenceObject $baselineJSON -Property entity, identifire, vendor, entityName, entityVersion, driverFamilyId -IncludeEqual

# Initialize result lists
$pass = @()
$differences = @()
$detailsList = @()

# --- Build structured list from comparison results ---
foreach ($item in $comparisonResult) {
    $detailsList += [PSCustomObject]@{
        entity        = $item.entity
        entityName    = $item.entityName
        entityVersion = $item.entityVersion
        sideIndicator = $item.SideIndicator
        detail        = "$($item.entityName)::" + "$($item.entityVersion)"
    }
}

# Sort by name, match direction, and version to make output stable
$sortedList = $detailsList | Sort-Object entityName, sideIndicator, entityVersion

# Check if any Intel UHD Graphics device passed – we'll use this to suppress duplicates
$intelUhdPassExists = ($sortedList | Where-Object {
    $_.entityName -like 'Intel(R) UHD Graphics' -and $_.sideIndicator -eq '=='
}).Count -gt 0

# Track which Intel UHD entries (by name + version) already passed
$passedUhdKeys = @{}

# --- Main comparison output loop ---
foreach ($entry in $sortedList) {

    # Special handling for Intel UHD Graphics (suppress duplicates)
    if ($entry.entityName -like 'Intel(R) UHD Graphics*') {
        $key = "$($entry.entityName):::$($entry.entityVersion)"

        # Skip if we've already accepted this entry as a PASS
        if ($passedUhdKeys.ContainsKey($key)) {
            continue
        }

        # If this is a matching PASS, record and output it
        if ($entry.sideIndicator -eq '==') {
            $passedUhdKeys[$key] = $true
            Write-Host "`n [pass] $($entry.detail)" -ForegroundColor Green
            $pass += @{status = 'pass'; detail = $entry.detail}
            continue
        }

        # Otherwise, let it fall through to standard rules
    }

    # --- Default handling for all devices ---
    switch ($entry.sideIndicator) {
        '==' {
            Write-Host "`n [pass] $($entry.detail)" -ForegroundColor Green
            $pass += @{status = 'pass'; detail = $entry.detail}
        }
        '=>' {
            if ($entry.detail -like '*Panel Drivers and Tools*') {
                $entry.detail += '::If you see an error here, make sure you are testing on a device with a panel'
            }
            Write-Host "`n [must] $($entry.detail)" -ForegroundColor Yellow
            Write-Output " [must] $($entry.detail)" | Out-File .\errors -Append
            $differences += @{status = 'must'; detail = $entry.detail}
        }
        '<=' {
            Write-Host "`n [fail] $($entry.detail)" -ForegroundColor Red
            Write-Output " [fail] $($entry.detail)" | Out-File .\errors -Append
            $differences += @{status = 'fail'; detail = $entry.detail}
        }
    }
}

# --- Export results to JSON ---
$pass | ConvertTo-Json -Depth 2 | Out-File -FilePath ".\output\_devicePass.json"
$differences | ConvertTo-Json -Depth 2 | Out-File -FilePath ".\output\_deviceFail.json"

# --- Wait for user confirmation before exit ---
Write-Host "`n Press any key to exit ..."
Read-Host
