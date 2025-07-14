Param([string]$InputFile)

$inputterVersion = "1.6.0.0"

$WarningPreference = 'SilentlyContinue'

$Debug = $false

function Get-IntelPSE {
    # Define the partial device description to search for
    $partialDeviceDescription = "*Integrated Sensor Solution*"

    # Run pnputil and get the connected devices
    $devices = pnputil /enum-devices /connected

    # Convert the output into a readable format
    $deviceLines = $devices | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

    # Initialize variables
    $currentDriver = $null
    $oemFile = $null

    # Variables to track device parsing
    $currentInstance = $null
    $currentDescription = $null

    # Process device output
    foreach ($line in $deviceLines) {
        # Capture the Instance ID
        if ($line -match "^Instance ID:\s+(.+)$") {
            $currentInstance = $matches[1]
            # Reset variables for a new device block
            $currentDescription = $null
            $currentDriver = $null
        }

        # Capture the Device Description
        if ($line -match "^Device Description:\s+(.+)$") {
            $currentDescription = $matches[1]
        }

        # Capture the Driver Name
        if ($line -match "^Driver Name:\s+(oem\d+\.inf)$") {
            $currentDriver = $matches[1]
        }

        # Check if the current device matches the search criteria
        if ($currentDescription -like $partialDeviceDescription -and $currentDriver) {
            $oemFile = $currentDriver
            break
        }
    }

    if ($oemFile) {
        # Path to the Windows INF directory
        $infFilePath = Join-Path -Path "$env:windir\inf" -ChildPath $oemFile

        if (Test-Path $infFilePath) {
            # Read the content of the .inf file
            $infContent = Get-Content -Path $infFilePath

            # Look for the DriverVer line and extract the version number
            $driverVerLine = $infContent | Where-Object { $_ -match "^DriverVer\s*=" }
            
            if ($driverVerLine -match "DriverVer\s*=\s*\d{2}/\d{2}/\d{4},(.+)$") {
                $versionNumber = $matches[1].Trim()
                return $versionNumber  # Return the extracted version number
            } else {
                Write-Output "DriverVer line not found or format is incorrect."
                return $null  # Return null if the format is incorrect
            }
        } else {
            Write-Output "The .inf file does not exist at the expected path: $infFilePath"
            return $null  # Return null if the file doesn't exist
        }
    } else {
        Write-Output "No matching device found with partial description like: $partialDeviceDescription"
        return $null  # Return null if no matching device is found
    }
}

function Get-DeviceDriverInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Identifier
    )

    # Run pnputil and get the connected devices
    $devices = pnputil /enum-devices /connected

    # Convert the output into a readable format
    $deviceLines = $devices | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

    # Initialize variables
    $currentDriver = $null
    $driverVersion = $null

    # Variables to track device parsing
    $currentInstance = $null
    $currentDescription = $null

    # Process device output
    foreach ($line in $deviceLines) {
        # Capture the Instance ID
        if ($line -match "^Instance ID:\s+(.+)$") {
            $currentInstance = $matches[1]
            # Reset variables for a new device block
            $currentDescription = $null
            $currentDriver = $null
        }

        # Capture the Device Description
        if ($line -match "^Device Description:\s+(.+)$") {
            $currentDescription = $matches[1]
        }

        # Capture the Driver Name
        if ($line -match "^Driver Name:\s+(oem\d+\.inf)$") {
            $currentDriver = $matches[1]
        }

        # Check if the current instance matches the identifier
        if ($currentInstance -like "*$Identifier*" -and $currentDriver) {
            # Path to the Windows INF directory
            $infFilePath = Join-Path -Path "$env:windir\inf" -ChildPath $currentDriver

            if (Test-Path $infFilePath) {
                # Read the content of the .inf file
                $infContent = Get-Content -Path $infFilePath

                # Look for the DriverVer line and extract the version number
                $driverVerLine = $infContent | Where-Object { $_ -match "^DriverVer\s*=" }

                if ($driverVerLine -match "DriverVer\s*=\s*\d{2}/\d{2}/\d{4},(.+)$") {
                    $driverVersion = $matches[1].Trim()
                }
            }
            break
        }
    }

    return $driverVersion
}

$scriptBlockDrivers = {
    try {
        return Get-CimInstance -ClassName Win32_PnpSignedDriver
    } catch {
        Write-Output "`n----------------------------------------------------------------"
        Write-Error "Error retrieving drivers information: $_"
        Write-Output "----------------------------------------------------------------`n"
    }
}

$allDrivers = & $scriptBlockDrivers

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-JsonFilePath {
    $openFileDialog = [System.Windows.Forms.OpenFileDialog]::new()
    $openFileDialog.Filter = "JSON Files (*.json)|*.json"

    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $openFileDialog.FileName
    } else {
        return $null
    }
}

Write-Output "`n----------------------------------------------------------------" 
Write-Output "  Inputter version: $inputterVersion"
Write-Output "----------------------------------------------------------------`n"

if (!$InputFile) {
	$wmi = Get-WmiObject -Class Win32_ComputerSystem
	$modelName = $wmi.Model.Trim()
	$modelNameParts = $modelName.Split(' ')
	if ($modelNameParts[0] -eq "SIMATIC") {
		$skip = 1

        if ($modelNameParts[1] -eq "IPC") { 
            $skip = 2
        }

		$modelNameParts = $modelNameParts | Select-Object -Skip $skip
		
        $name = $modelNameParts -join " "

		if ($name -eq "BX-39A") { $name = "xX-39A" }
		if ($name -eq "PX-39A") { $name = "xX-39A" }
		if ($name -eq "PX-39A PRO") { $name = "xX-39A" }
		
		if ($name -eq "BX-32A") { $name = "xX-32A" }
		if ($name -eq "PX-32A") { $name = "xX-32A" }
		
		if ($name -eq "RW-528A") { $name = "RW-5x8A" }
		if ($name -eq "RW-548A") { $name = "RW-5x8A" }
		
		if ($name -eq "627E") { $name = "6x7E" }
		if ($name -eq "677E") { $name = "6x7E" }
		
	} else {
		$name = "Unknow"
	}
	
	$deviceMaskFile = ".\_deviceMask\*$name*.*"
	if (Test-Path $deviceMaskFile) {
			Write-Output "`n----------------------------------------------------------------"
			Write-Output "  Device configuration mask successfully loaded from: "
			Write-Output "  $deviceMaskFile  "
			Write-Output "----------------------------------------------------------------`n"
			$jsonContent = $deviceMaskFile
			Write-Output $deviceMaskFile
	} else {
			Write-Output "`n----------------------------------------------------------------"   
			Write-Output "  Please manually select the device mask."
			Write-Output "----------------------------------------------------------------`n"
			$jsonContent = Get-JsonFilePath
	}
} else {
	Write-Output "`n----------------------------------------------------------------"
	Write-Output "  Device configuration mask successfully loaded from: "
	Write-Output "  $InputFile  "
	Write-Output "----------------------------------------------------------------`n"
    $jsonContent = $InputFile
}

try {
	$jsonContent = Get-Content -Path $jsonContent | ConvertFrom-Json
	Write-Output "`n----------------------------------------------------------------"
	Write-Output "  JSON Data Successfully Imported and Ready for Processing"
	Write-Output "----------------------------------------------------------------`n"
} catch {
	Write-Output "`n----------------------------------------------------------------"
	Write-Error "  Error encountered while reading or parsing the JSON file." 
	Write-Error "  Error details: $_. "
	Write-Output "----------------------------------------------------------------`n"
	Read-Host
	exit
}

$scriptBlockApps = {
    try {
        # Collecting UWP apps information for all users
        $uwpApps = Get-AppxPackage -AllUsers

        # Define patterns to exclude apps that contain specific text
        $excludePatterns = @{
			"IntelVirtualRAIDonCPUStorageManagementApp" = $true
            "IntelOptaneMemoryandStorageManagement" = $true
            "IntelManagementandSecurityStatus" = $true
            "IntelGraphicsExperience" = $true
            "RealtekAudioControl" = $true
            "NVIDIAControlPanel" = $true
			"Microsoft.WindowsCamera" = $true
			"ThunderboltControlCenter" = $true
        }

        # Custom function to clean package name
        function Remove-PackageVersion {
            param($name)
            switch -Wildcard ($name) {
                "SIMATIC IPC Panel Drivers and Tools*" { return "SIMATIC IPC Panel Drivers and Tools" }
                "SIMATIC IPC ORCLA*" { return "SIMATIC IPC ORCLA" }
                "SIMATIC IPC DiagBase*" { return "SIMATIC IPC DiagBase" }
                default { return ($name -replace ' \d+(\.\d+)*$', '') }
            }
        }

        # Collect information on classic apps, excluding UWP apps
		# Get packages from Get-Package -ProviderName Programs
		$packagePrograms = Get-Package -ProviderName Programs | Select-Object Name, Version, ProviderName, Status

		# Get packages from Get-WmiObject -Class Win32_Product
		$packageWmi = Get-WmiObject -Class Win32_Product | Select-Object @{Name="Name";Expression={$_.Name}}, 
															   @{Name="Version";Expression={$_.Version}}

		# Combine both results into $packages
		$packages = $packagePrograms + $packageWmi
		
		if ($Debug) { 
			Write-Host $packages | Format-Table -AutoSize 
			Read-Host
		}

        # Remove duplicates based on cleaned Name
        $uniquePackages = @{}
        foreach ($package in $packages) {
            $nameWithoutVersion = Remove-PackageVersion $package.Name
            if (-not $uniquePackages.ContainsKey($nameWithoutVersion)) {
                $uniquePackages[$nameWithoutVersion] = $package
            }
        }
        $uniquePackages = $uniquePackages.Values

        # Return information in a hashtable, separated for UWP and classic apps
        return @{ "UWP" = $uwpApps; "Classic" = $uniquePackages }

    } catch {
        Write-Error "Error retrieving app information: $_"
    }
}

# Define a script block for collecting device information
$scriptBlockDevices = {
    try {
        return Get-CimInstance -ClassName Win32_PnPEntity
    } catch {
        Write-Output "`n----------------------------------------------------------------"
        Write-Error "Error retrieving device information: $_"
        Write-Output "----------------------------------------------------------------`n"
    }
}

$appData = & $scriptBlockApps
$deviceInfo = & $scriptBlockDevices

# Define a hashtable for vendor transformations
$vendorTransformation = @{
    "CN=EB51A5DA-0E72-4863-82E4-EA21C1F8DFE3" = "Intel Corporation"
    "CN=83564403-0B26-46B8-9D84-040F43691D31" = "Realtek Semiconductor Corp"
    "CN=D6816951-877F-493B-B4EE-41AB9419C326" = "Nvidia Corporation"
	"CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US" = "Microsoft Corporation"
}

# Define a hashtable for program name transformations
$programNameTransformation = @{
    "AppUp.IntelGraphicsExperience" = "Intel® Graphics Command Center"
    "AppUp.IntelOptaneMemoryandStorageManagement" = "Intel® Optane™ Memory and Storage Management"
    "AppUp.IntelManagementandSecurityStatus" = "Intel® Management and Security Status"
	"AppUp.IntelVirtualRAIDonCPUStorageManagementApp" = "Intel® Virtual Raid on CPU Management"
    "RealtekSemiconductorCorp.RealtekAudioControl" = "Realtek Audio Console"
    "NVIDIACorp.NVIDIAControlPanel" = "Nvidia Control Panel"
	"Microsoft.WindowsCamera" = "Microsoft Windows Camera"
	"AppUp.ThunderboltControlCenter" = "Thunderbolt Control Center"
}

# Assuming $deviceInfo is predefined elsewhere as all available devices
$deviceInfoList = New-Object System.Collections.Generic.List[Object]
$deviceConfig = $jsonContent.deviceConfig

# Process each device configuration
foreach ($device in $deviceConfig) {
    $entity = $device.entity
    $identifier = $device.identifier
    $driverFamilyId = $device.driverFamilyId
	Write-Host $device.driverFamilyId


    # Filter device information based on device and deviceID
    $hardwareDevice = $deviceInfo | Where-Object { $_.PNPDeviceID -like "*$entity*$identifier*" }
    
    if ($hardwareDevice) {
        if ($Debug) { Write-Output "Hardware device detected: $hardwareDevice" }
        $vendor = $hardwareDevice.Manufacturer
        $deviceName = $hardwareDevice.Name
        $deviceName = $hardwareDevice.Name.Replace('\u0026', '&')

        $driverInfo = $allDrivers | Where-Object { $_.DeviceName -eq $deviceName }

        $driverVersion = if ($driverInfo) { $driverInfo.DriverVersion } else { "Error" }
		if ($Debug) { Write-Output "$driverVersion by VEN/DEV"}
		
        if ($identifier -eq "DEV_4BB3") {
            $driverVersion = Get-IntelPSE
        }

		
        $deviceInfoObject = [PSCustomObject]@{
            entity = $entity
            identifier = $identifier
            vendor = $vendor
            entityName = $deviceName
            entityVersion = $driverVersion
            driverFamilyId = $driverFamilyId
        }
		if ($deviceInfoObject.entityVersion -is [System.Collections.IList]) {
			$deviceInfoObject.entityVersion = $deviceInfoObject.entityVersion | Where-Object { $_ -ne "null" -and $_ -ne $null } | Select-Object -First 1
		} elseif ($deviceInfoObject.entityVersion -match '\d+\.\d+\.\d+\.\d+') {
			$deviceInfoObject.entityVersion = $matches[0]
		}
		
		if ($Debug) { Write-Output "entityVersion by VEN/DEV: $deviceInfoObject.entityVersion"}
		
		if ($deviceInfoObject.entityVersion -is [System.Collections.IList]) {
			$deviceInfoObject.entityVersion = $deviceInfoObject.entityVersion | Where-Object { $_ -ne "null" -and $_ -ne $null } | Select-Object -First 1
		}
		
        $deviceInfoList += $deviceInfoObject
    } else {
		# Classic Apps
        foreach ($app in $appData.Classic) {
            $programVendor = $app.Vendor
            $programName = $app.Name
            $programVersion = $app.Version

            if ($programName -like "*$entity*") {
                if ($Debug) { Write-Output "Classic App detected: $programName" }

				if ($entity -eq "Win2022") {
					$programName = "Aspeed Display"
				}

                $deviceInfoObject = [PSCustomObject]@{
                    entity = $entity
                    identifier = $identifier
                    vendor = $programVendor
                    entityName = $programName
                    entityVersion = $programVersion
                    driverFamilyId = $driverFamilyID 
                }
                if ($deviceInfoObject.entityVersion -match '\d+\.\d+\.\d+\.\d+') {
                    $deviceInfoObject.entityVersion = $matches[0]  
                }
                $deviceInfoList += $deviceInfoObject
            }
        }
		# UWP Apps
        foreach ($app in $appData.UWP) {
                $programVendor = $app.Publisher
                $programName = $app.Name
                $programVersion = $app.Version

                # Check if the program name matches the device name
               if ($programName -like "*$entity*") {
                if ($Debug) { Write-Output "UWP App detected: $programName" }


                if ($vendorTransformation.ContainsKey($programVendor)) {
                    $programVendor = $vendorTransformation[$programVendor]
                }

                $programName = if ($programNameTransformation.ContainsKey($programName)) {
                    $programNameTransformation[$programName]
                } else {
                    $entity
                }


                $deviceInfoObject = [PSCustomObject]@{
                    entity = $entity
                    identifier = $identifier
                    vendor = $programVendor
                    entityName = $programName
                    entityVersion = $programVersion
                    driverFamilyId = $driverFamilyId 
                }
                $deviceInfoList += $deviceInfoObject
            }
        }
    }
}

# Convert the deviceInfoList to JSON and save it
try {
	$deviceInfoList | ConvertTo-Json -Depth 3 | Set-Content -Path ".\output\_autovalidation.json"
	Write-Output "`n----------------------------------------------------------------"
	Write-Output "  Device information successfully saved to the JSON file: "
	Write-Output "  .\output\_autovalidation.json "
	Write-Output "----------------------------------------------------------------`n"
	Write-Output "Exported $($deviceInfoList.Count) entries."
} catch {
	Write-Output "`n----------------------------------------------------------------"
	Write-Error "  Error encountered while saving device information to JSON. "
	Write-Error "  Error details: $_. Please verify the file path and permissions."
	Write-Output "----------------------------------------------------------------`n"
}

# Run device Mask validator
. ".\core\_validator.ps1"