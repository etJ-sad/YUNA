Param([string]$InputFile)
$version = "v1.100.05"

$DEBUG = $InputFile
#$DEBUG = "OFF"

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web.Extensions
Add-Type -AssemblyName WindowsBase

cd ${PSScriptRoot}
cd ..
$iconPath = Join-Path (Get-Location) -ChildPath "icon.ico"
cd ${PSScriptRoot}

#$iconPath = "${PSScriptRoot}\icon.ico"
$tabControl = New-Object System.Windows.Controls.TabControl

if ($DEBUG -eq "OFF"){
	# Ignore Errors
	$ErrorActionPreference = 'silentlycontinue'

	# Hide PowerShell Console
	Add-Type -Name Window -Namespace Console -MemberDefinition '
	[DllImport("Kernel32.dll")]
	public static extern IntPtr GetConsoleWindow();

	[DllImport("user32.dll")]
	public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
	'
	$consolePtr = [Console.Window]::GetConsoleWindow()
	[Console.Window]::ShowWindow($consolePtr, 0)
	
	if ([System.Threading.Thread]::CurrentThread.CurrentUICulture.Name -ne 'en-US') {
		[System.Windows.MessageBox]::Show("Windows locale is not set to English (en-US). Please reinstall Windows and select English as the main language during the Out Of Box Experience.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
		exit
	}
}

$loadingWindow = New-Object System.Windows.Window
$loadingGrid = New-Object System.Windows.Controls.Grid
$loadingLabel = New-Object System.Windows.Controls.Label

function Show-LoadingScreen {
    $loadingWindow.Title = $version +  " Loading... "  
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

	if (Test-Path $iconPath) {
		$icon = New-Object System.Windows.Media.Imaging.BitmapImage
		$icon.BeginInit()
		$icon.UriSource = New-Object System.Uri($iconPath)
		$icon.EndInit()
		$loadingWindow.Icon = $icon
	} else {
		Write-Output "Icon file not found: $iconPath"
	}
	
	$loadingWindow.Show()| Out-Null
}

function Close-LoadingScreen {
    $loadingWindow.Close()
}

Show-LoadingScreen

if (Test-Path "${PSScriptRoot}\errors") { Remove-Item "${PSScriptRoot}\errors" -Force }
if (Test-Path "${PSScriptRoot}\output\__FullReport.json") { Remove-Item "${PSScriptRoot}\output\_systemRecoveryMenu.json" -Force }
if (Test-Path "${PSScriptRoot}\output\__FullReport.json") { Remove-Item "${PSScriptRoot}\output\_systemReset.json" -Force }

$filesToDelete = @(
    "__FullReport.json",
    "_installedDrivers.json",
    "_installedSoftware.json",
    "_partition.json",
    "_powerSchema.json",
    "_version.json",
    "_autovalidation.json",
    "_devicePass.json",
    "_deviceFail.json",
	"_eventLog.json",
	"_port135Status.json",
	"_port445Status.json",
	"_port63105Status.json",
	".currentInstalledWindowsUpdates.json",
	"_defaultAppAssociations.xml",
	"FullReport.html"
)

foreach ($file in $filesToDelete) {
    $filePath = Join-Path -Path "${PSScriptRoot}\output\" -ChildPath $file
    If (Test-Path $filePath) { Remove-Item $filePath -Force }
}

# Create Main Window
$mainWindow = New-Object System.Windows.Window
$mainWindow.WindowStartupLocation = "CenterScreen"
$mainWindow.Title = "ScriptSync " + $version
$mainWindow.Width = 900
$mainWindow.Height = 820
$mainWindow.ResizeMode = "NoResize"

if (Test-Path $iconPath) {
	$icon = New-Object System.Windows.Media.Imaging.BitmapImage
	$icon.BeginInit()
	$icon.UriSource = New-Object System.Uri($iconPath)
	$icon.EndInit()
	$mainWindow.Icon = $icon
} else {
	Write-Output "Icon file not found: $iconPath"
}

# Include Scripts
. ".\core\.objects.ps1"
. ".\core\version.ps1"
. ".\core\installedSoftware.ps1"
. ".\core\installedDrivers.ps1"
. ".\core\partition.ps1"
. ".\core\powerschema.ps1"
. ".\core\eventLog.ps1"
. ".\core\report.ps1"
. ".\core\misc.ps1"

# Append Tabs to TabControl

#ROW 1
$auditLabelTab = New-Object System.Windows.Controls.TabItem
$auditLabelTab.Header = "Audit"
$auditLabelTab.IsEnabled = $false
$tabControl.Items.Add($auditLabelTab)

if (Test-Path "C:\Windows\ConfigSetRoot") { 
		#[System.Windows.MessageBox]::Show("Error: ScriptSync cannot be executed in Windows Audio mode. Please complete your image setup and run ScriptSync in Windows Runtime.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
	Show-InstalledSoftwareTab
	Show-InstalledDriversTab
	Show-VersionTab
	
	Close-LoadingScreen
	
	$tabControl.SelectedIndex = 1
	
	$mainWindow.Content = $tabControl
	$mainWindow.ShowDialog() | Out-Null
} else {
	Show-InstalledSoftwareTab
	Show-InstalledDriversTab

	function OpenDeviceManager {
		$deviceManagerPath = "C:\Windows\System32\devmgmt.msc"
		if (Test-Path $deviceManagerPath) {
			Start-Process $deviceManagerPath
		} else {
			Write-Output "Device Manager not found"
		}
	}

	$deviceManagerTab = New-Object System.Windows.Controls.TabItem
	$deviceManagerTab.Header = "Device Manager"
	$tabControl.Items.Add($deviceManagerTab)
	$tabControl.Add_SelectionChanged({
		if ($tabControl.SelectedItem -eq $deviceManagerTab) {
			OpenDeviceManager
			$tabControl.SelectedIndex = 7
		}
	})

	Show-ReportTab

	# `n 
	$splitTab1 = New-Object System.Windows.Controls.TabItem
	$splitTab1.Header = "                                                                " #END
	$splitTab1.IsEnabled = $false 
	$tabControl.Items.Add($splitTab1)

	#ROW 0
	$validateLabelTab = New-Object System.Windows.Controls.TabItem
	$validateLabelTab.Header = "Validate"
	$validateLabelTab.IsEnabled = $false
	$tabControl.Items.Add($validateLabelTab)

	Show-VersionTab
	Show-PartitionTab
	Show-PowerSchemaTab
	Show-EventLogTab
	Show-MiscTab

	$tabControl.SelectedIndex = 7

	# Close LoadingScreen
	Close-LoadingScreen

	if (Test-Path "${PSScriptRoot}\errors") {
		[System.Windows.MessageBox]::Show("Errors have been identified during the validation process.", "Errors detected", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
		. ".\core\errors.ps1"
		Show-ErrorsTab
	}

	if (Test-Path "${PSScriptRoot}\core\settings.ps1") {
		. ".\core\settings.ps1"
		Show-SettingsTab
	}

	if (Test-Path "${PSScriptRoot}\core\api.ps1") {
		. ".\core\api.ps1"
		Show-APITab
	}

	$mainWindow.Content = $tabControl
	$mainWindow.ShowDialog() | Out-Null
}
