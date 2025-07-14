# CREATE_VERSION_JSON_FILE.ps1 - Subscript for YUNA (Yielding Universal Node Automation)
#
# This script is responsible for:
# - Loading necessary .NET assemblies to support WPF-based UI elements.
# - Displaying a loading screen during application initialization.
# - Gathering detailed system and image version information including:
#     • Device model and related model mappings.
#     • Base operating system details (Product Name, Display Version, Build, Variant).
#     • Version information, driver baseline, image build, and part number.
#     • Timestamps for creation and deployment events.
# - Presenting the collected data in a user-friendly WPF window with a tabbed interface.
# - Allowing user confirmation via a button, which triggers the export of the version data to a JSON file (C:\Version.json).
# - Collecting and exporting installed Microsoft Updates (KBs) to a JSON file.
# - Providing a robust UI experience with progress indicators and clear messaging.

$version = "$($config.Version)"

$ErrorActionPreference = 'silentlycontinue'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web.Extensions
Add-Type -AssemblyName WindowsBase

# Determine the root directory five levels above $PSScriptRoot
$rootPath = $PSScriptRoot
for ($i = 0; $i -lt 5; $i++) {
    $rootPath = Split-Path -Parent $rootPath
}

# Build the path to current_stage.json in that root directory
$configPath = Join-Path -Path $rootPath -ChildPath "current_stage.json"

if (Test-Path $configPath) {
    $current_stage = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    # Check if the imageType is either "RESEALED" or "RECOVERY"
    if (($current_stage.imageType -eq "RESEALED") -or ($current_stage.imageType -eq "RECOVERY")) {
        $selectedImage = $current_stage
    }
    else {
        Write-Host "RESEALED or RECOVERY IMAGE configuration not found in current_stage.json"
        exit 1
    }
}
else {
    Write-Host "Configuration file not found: $configPath"
    exit 1
}

<# Hide PowerShell Console
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0)
#>

$loadingWindow = New-Object System.Windows.Window
$loadingGrid = New-Object System.Windows.Controls.Grid
$loadingLabel = New-Object System.Windows.Controls.Label

function Show-LoadingScreen {
    $loadingWindow.Title = $version + " Loading... "  
    $loadingWindow.Width = 300
    $loadingWindow.Height = 150
    $loadingWindow.WindowStartupLocation = "CenterScreen"

    $loadingLabel.Content = "Please wait while the application is loading..."
    $loadingLabel.HorizontalAlignment = "Center"
    $loadingLabel.VerticalAlignment = "Top"
    $loadingLabel.Margin = "0,40,0,0"
    $loadingWindow.FontSize = 14

    $loadingGrid.Children.Add($loadingLabel)
    $loadingWindow.Content = $loadingGrid
	
	$loadingWindow.Show() | Out-Null
}

function Close-LoadingScreen {
    $loadingWindow.Close()
}

Show-LoadingScreen

$versionAsJSON = $null
$panel = New-Object System.Windows.Controls.StackPanel
$versionTable = New-Object System.Data.DataTable
$versionTab = New-Object System.Windows.Controls.TabItem
$versionTabGrid = New-Object System.Windows.Controls.DataGrid
$exportButton = New-Object System.Windows.Controls.Button

$versionTabGrid.AutoGenerateColumns = $true
$versionTabGrid.ColumnWidth = "*"

function Show-VersionTab() {
    $versionTab.Header = "Windows Image Version"

    $versionTabGrid.HorizontalAlignment = "Stretch"
    $versionTabGrid.VerticalAlignment = "Top"
    $versionTabGrid.Margin = "1,1,1,1"

    $versionTable.Columns.Add("About")
    $versionTable.Columns.Add("Value")
    $versionTabGrid.FontSize = 13
	
    # DeviceModelName
    $deviceName = $versionTable.NewRow()
    $wmi = Get-WmiObject -Class Win32_ComputerSystem
    $modelName = $wmi.Model
    $deviceName["About"] = "DeviceModelName"

    # Device Hash-Array
    $modelRelationships = @{
        ## Embedded ---
        "SIMATIC IPC BX-39A" = @("SIMATIC IPC PX-39A", "SIMATIC IPC PX-39A PRO")
        "SIMATIC IPC PX-39A" = @("SIMATIC IPC BX-39A", "SIMATIC IPC PX-39A PRO")
        "SIMATIC IPC PX-39A PRO" = @("SIMATIC IPC BX-39A", "SIMATIC IPC PX-39A")
		
        # xX-32A
        "SIMATIC IPC BX-32A" = @("SIMATIC IPC PX-32A")
        "SIMATIC IPC PX-32A" = @("SIMATIC IPC BX-32A")
		
        # BX-54A
        "SIMATIC BX-54A" = ""
		
        # BX-56A IPC 59A
        "SIMATIC IPC BX-56A" = @("SIMATIC IPC BX-59A")
        "SIMATIC IPC BX-59A" = @("SIMATIC IPC BX-56A")
		
        # 4x7E
        "SIMATIC IPC427E" = @("SIMATIC IPC477E")
        "SIMATIC IPC477E" = @("SIMATIC IPC427E")
		
        # 2x7E
        "SIMATIC IPC227E" = @("SIMATIC IPC277E")
        "SIMATIC IPC277E" = @("SIMATIC IPC227E")
		
        # 2x7G
        "SIMATIC IPC227G" = @("SIMATIC IPC277G", "SIMATIC IPC277G PRO")
        "SIMATIC IPC277G" = @("SIMATIC IPC227G", "SIMATIC IPC227G PRO")
        "SIMATIC IPC277G PRO" = @("SIMATIC IPC227G", "SIMATIC IPC277G")
		
        # 127E
        "SIMATIC IPC127E" = ""
		
        # 127E
        "SIMATIC BX-21A" = ""
		
        ## Rack ---
        "SIMATIC IPC1047E" = ""
        "SIMATIC IPC647E" = @("SIMATIC IPC847E")
        "SIMATIC IPC847E" = @("SIMATIC IPC647E")
        "SIMATIC IPC RC-545A" = ""
        "SIMATIC IPC RW-545A" = ""
        "SIMATIC IPC RS-545A" = ""
        "SIMATIC IPC RW-528A" = @("SIMATIC IPC RW-548A")
        "SIMATIC IPC RW-548A" = @("SIMATIC IPC RW-528A")
        "SIMATIC IPC RW-543A" = ""
        "SIMATIC IPC527G" = ""
        "SIMATIC IPC RS-717A" = ""
        "SIMATIC IPC RS-828A" = ""
        "SIMATIC IPC547J" = ""
        "SIMATIC IPC627E" = @("SIMATIC IPC677E")
        "SIMATIC IPC677E" = @("SIMATIC IPC627E")
		
        ## Mobile ---
        "SIMATIC IPC MD-57A" = ""
        "SIMATIC FIELD PG M6" = ""
        "SIMATIC FIELD PG M5" = ""
        "SIMATIC IPC MD-34A" = ""
        "SIMATIC ITP1000" = ""
    }

    if ($modelRelationships.ContainsKey($modelName)) {
        $relatedModels = $modelRelationships[$modelName]
        if ($relatedModels -eq "") {
            $modelName = $modelName
        } else {
            $modelName = $modelName + " / " + ($relatedModels -join " / ")
        }
    } else {
        $modelName = "Unknown or not defined device: $modelName"
    }

    $deviceName["Value"] = $modelName
    $versionTable.Rows.Add($deviceName)

	# BaseOperatingSystemVersion INIT
    $osDisplayVersionReg = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion).DisplayVersion
	
	# BaseOperatingSystem
    $osBaseOperatingSystem = $versionTable.NewRow()
    $osProductName = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\" -Name "ProductName"
	$osProductNameReg = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\" -Name "ProductName"
	
	if ($osDisplayVersionReg -like "*24H2*"){
			$osProductName = "Windows 11 IoT Enterprise"
	}    

	if ($osProductNameReg -like "*LTSC 2024*") {
			$osProductName = "Windows 11 IoT Enterprise LTSC 2024"
	}
	
    $osBaseOperatingSystem["About"] = "BaseOperatingSystem"
    $osBaseOperatingSystem["Value"] = $osProductName
    $versionTable.Rows.Add($osBaseOperatingSystem)
    
    # BaseOperatingSystemVersion
    $osDisplayVersion = $versionTable.NewRow()
    $osDisplayVersion["About"] = "BaseOperatingSystemVersion"
    $osDisplayVersion["Value"] = $osDisplayVersionReg
    $versionTable.Rows.Add($osDisplayVersion)

    # BaseOperatingSystemBuild
    $osBuild = $versionTable.NewRow()
    $osBuild["About"] = "BaseOperatingSystemBuild"
    if (Test-Path "C:\Windows\Panther\Siemens\.osBuildVersion.json") {
        $osBuildVersionFile = Get-Content "C:\Windows\Panther\Siemens\.osBuildVersion.json" -Raw | ConvertFrom-Json
        $osBuildVersion = $osBuildVersionFile.OSBuildVersion
        $osBuild["Value"] = $osBuildVersion	
    } else {
        $osBuildVersionArray = Invoke-Expression -Command "cmd /c ver"
        $osBuildVersion = $osBuildVersionArray -split ' '
        $osBuildVersionAsText = $osBuildVersion[4]
        $lastIndex = $osBuildVersionAsText.LastIndexOf("]")
        $osBuildVersionAsText = $osBuildVersionAsText.Substring(0, $lastIndex)
        $osBuildVersionAsText = $osBuildVersionAsText.Substring(5, 10)
		
        $osBuild["Value"] = "=> Warning: captured from system information: " + $osBuildVersionAsText
    }
    $versionTable.Rows.Add($osBuild)
	
    # BaseOperatingSystemVariant
    $osVariant = $versionTable.NewRow()
    $osVariant["About"] = "BaseOperatingSystemVariant"
    if ($current_stage.imageVariant) {
        $osVariant["Value"] = $current_stage.imageVariant
    } else {
        $osVariant["Value"] = "imageVariant not defined in config.json"
    }
    $versionTable.Rows.Add($osVariant)
	
    # Version
    $osVersion = $versionTable.NewRow()
    $osVersion["About"] = "Version"
    if (Test-Path "C:\Windows\Panther\Siemens\.updateLevel.json") {
        $updateLevelFile = Get-Content "C:\Windows\Panther\Siemens\.updateLevel.json" -Raw | ConvertFrom-Json
        $updateLevel = $updateLevelFile.updateLevel
        $osVersion["Value"] = $updateLevel
    } else {
        $currentDate = Get-Date -Format MM-yyyy
        $osVersion["Value"] = "=> Warning: captured from system date: " + $currentDate 
    }
    $versionTable.Rows.Add($osVersion)
	
    # OsImageCreator
    $osImageCreator = $versionTable.NewRow()
    $osImageCreator["About"] = "OsImageCreator"
    $osImageCreator["Value"] = "Siemens AG"
    $versionTable.Rows.Add($osImageCreator)

    # OsVendor
    $osVendor = $versionTable.NewRow()
    $osVendor["About"] = "OsVendor"
    $osVendor["Value"] = "Microsoft Corporation"
    $versionTable.Rows.Add($osVendor)

    # Driver Baseline 
    $driverBaseline = $versionTable.NewRow()
    $driverBaseline["About"] = "UsedDriverBaseline"
    if ($current_stage.usedDriverBaseline) {
        $driverBaseline["Value"] = $current_stage.usedDriverBaseline
    } else {
        $driverBaseline["Value"] = "DRVBASELINE not defined in config.json"
    }
    $versionTable.Rows.Add($driverBaseline)

    # Image Build 
    $imageBuild = $versionTable.NewRow()
    $imageBuild["About"] = "ImageBuild"
    if ($current_stage.imageBuild) {
        $imageBuild["Value"] = $current_stage.imageBuild
    } else {
        $imageBuild["Value"] = "IMAGEBUILD not defined in config.json"
    }
    $versionTable.Rows.Add($imageBuild)

    # PartNumber A5E 
    $osPartNumber = $versionTable.NewRow()
    $osPartNumber["About"] = "PartNumber"
    if ($current_stage.A5E) {
        $osPartNumber["Value"] = $current_stage.A5E
    } else {
        $osPartNumber["Value"] = "A5E not defined in config.json"
    }
    $versionTable.Rows.Add($osPartNumber)
	
    # Created - WinOS
    $currentDate = Get-Date
    $formattedDate = $currentDate.ToString("yyyy-MM-ddTHH:mm:sszzz")
    $osCreated = $versionTable.NewRow()
    $osCreated["About"] = "Created"
    $osCreated["Value"] = $formattedDate
    $versionTable.Rows.Add($osCreated)
	
    # Deployed - Manufacturer
    $osDeployed = $versionTable.NewRow()
    $osDeployed["About"] = "Deployed"
    $osDeployed["Value"] = ""
    $versionTable.Rows.Add($osDeployed)
	
    # First Booted - Customer (Windows Runtime)
    $firstBooted = $versionTable.NewRow()
    $firstBooted["About"] = "FirstBooted"
    $firstBooted["Value"] = ""
    $versionTable.Rows.Add($firstBooted)

    $saveButton = New-Object System.Windows.Controls.Button
    $saveButton.Content = "All data are correct"
    $saveButton.Add_Click({
        Export-VersionToJson
        if (Test-Path -Path "C:\Version.json") {
			$inputJsonFilePath = "C:\Version.json"			
			$jsonContent = Get-Content -Path $inputJsonFilePath -Raw
			$jsonObject = $jsonContent | ConvertFrom-Json

			# version
			$outputJsonFilePath = ".\.ScriptSync\_validation\.version.json"
			$keyValue = $jsonObject.Version
			$newJsonObject = @{
				"version" = $keyValue
			}
			$newJsonContent = $newJsonObject | ConvertTo-Json -Depth 10
			Set-Content -Path $outputJsonFilePath -Value $newJsonContent
			Write-Host "Version info saved in JSON: $outputJsonFilePath"

			# baseline
			$outputJsonFilePath = ".\.ScriptSync\_validation\.baseline.json"
			$keyValue = $jsonObject.UsedDriverBaseline
			$newJsonObject = @{
				"baseline" = $keyValue
			}
			$newJsonContent = $newJsonObject | ConvertTo-Json -Depth 10
			Set-Content -Path $outputJsonFilePath -Value $newJsonContent
			Write-Host "Driver baseline saved in JSON: $outputJsonFilePath"

			# imageBuild
			$outputJsonFilePath = ".\.ScriptSync\_validation\.imageBuild.json"
			$keyValue = $jsonObject.ImageBuild
			$newJsonObject = @{
				"imageBuild" = $keyValue
			}
			$newJsonContent = $newJsonObject | ConvertTo-Json -Depth 10
			Set-Content -Path $outputJsonFilePath -Value $newJsonContent
			Write-Host "Image build info saved in JSON: $outputJsonFilePath"

			# A5E
			$outputJsonFilePath = ".\.ScriptSync\_validation\.A5E.json"
			$keyValue = $jsonObject.PartNumber
			$newJsonObject = @{
				"A5E" = $keyValue
			}
			$newJsonContent = $newJsonObject | ConvertTo-Json -Depth 10
			Set-Content -Path $outputJsonFilePath -Value $newJsonContent
			Write-Host "Part number (A5E) saved in JSON: $outputJsonFilePath"
			
            MicrosoftUpdatesKBs
			
            [System.Windows.MessageBox]::Show("Version.json is now located in C:\.", "Creating Version.json file", `
                [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            $mainWindow.Close()
        } else {
            [System.Windows.MessageBox]::Show("Error occurred while creating C:\Version.json. Please ensure that you have write permissions on drive C:\ ", `
                "Creating Version.json file", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }                
    })

    # Append Content
    $versionTabGrid.ItemsSource = $versionTable.DefaultView
    $panel.AddChild($versionTabGrid)
    $panel.AddChild($saveButton)
    
    $versionTab.Content = $panel
    $tabControl.Items.Add($versionTab)
}

function MicrosoftUpdatesKBs {
    $kbNumbers = @()
    
    <#
    $files = Get-ChildItem -Path . -Recurse -Include *.cab, *.msu
    foreach ($file in $files) {
        if ($file.Name -match '(?i)kb(\d+)') {
            $kbNumbers += "KB$($matches[1])"
        }
    }
    #>
	
    $hotfixes = Get-Hotfix
    foreach ($hotfix in $hotfixes) {
        if ($hotfix.HotFixID -match '(?i)kb(\d+)') {
            $kbNumbers += $hotfix.HotFixID
        }
    }

    $kbNumbersUnique = $kbNumbers | Select-Object -Unique | Sort-Object

    $jsonFilePath = "C:\Windows\Panther\Siemens\.installedWindowsUpdates.json"
    $data = @{}
    for ($i = 0; $i -lt $kbNumbersUnique.Count; $i++) {
        $update = "Update$($i+1)"
        $data[$update] = $kbNumbersUnique[$i]
    }
    $jsonData = $data.GetEnumerator() | Sort-Object Value | Select-Object -Property Key, Value | ConvertTo-Json
    $jsonData | Out-File -FilePath $jsonFilePath

    Write-Host "Microsoft Updates KB saved in JSON: $jsonFilePath"
}

function Export-VersionToJson {
    param(
        [bool]$fullReport = $false
    )

    $versionAsJSON = [ordered]@{}
    foreach ($row in $versionTable.Rows) {
        $versionAsJSON[$row["About"]] = $row["Value"] -replace "`n", ""
    }
	
    $versionAsJSON | ConvertTo-Json -Depth 2 | Out-File -Encoding UTF8 C:\Version.json
}

$mainWindow = New-Object System.Windows.Window
$mainWindow.WindowStartupLocation = "CenterScreen"
$mainWindow.Title = $version
$mainWindow.Width = 850
$mainWindow.Height = 420
$mainWindow.ResizeMode = "NoResize"

$tabControl = New-Object System.Windows.Controls.TabControl

Show-VersionTab

$mainWindow.Content = $tabControl

Close-LoadingScreen
$mainWindow.ShowDialog() | Out-Null
