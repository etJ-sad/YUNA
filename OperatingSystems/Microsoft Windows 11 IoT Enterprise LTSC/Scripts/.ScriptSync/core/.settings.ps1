$settingsJson = $null

$settingsTabItem = New-Object System.Windows.Controls.TabItem
$settingsTextBox = New-Object System.Windows.Controls.TextBox
$settingsTextBox.AcceptsReturn = $true
$settingsTextBox.AcceptsTab = $true
$settingsTextBox.VerticalScrollBarVisibility = 'Visible'
$settingsTextBox.HorizontalScrollBarVisibility = 'Auto'
$settingsTextBox.IsReadOnly = $true
$settingsTextBox.TextWrapping = 'Wrap'

function Show-SettingsTab {
    $settingsTabItem.Header = "Settings"
	
	$versionExportButton.Visibility = 'Visible'
	$installedSoftwareExportButton.Visibility = 'Visible'
	$installedDriversExportButton.Visibility = 'Visible'
	$validateInstalledDriversExportButton.Visibility = 'Visible'
	$partitionExportButton.Visibility = 'Visible'
	$powerSchemaExportButton.Visibility = 'Visible'
	$systemResetExportButton.Visibility = 'Visible'
	$systemRecoveryMenuExportButton.Visibility = 'Visible'
	$eventLogExportButton.Visibility = 'Visible'
    
	$settingsTextBox.Text = "The following buttons are visible:`n" +
							"- Version Export`n" +
							"- Installed Software Export`n" +
							"- Installed Drivers Export`n" +
							"- Validate Installed Drivers Export`n" +
							"- Partition Export`n" +
							"- Power Schema Export`n" +
							"- System Reset Export`n" +
							"- System Recovery Menu Export`n" +
							"- Event Log Export."
    
    $settingsTabItem.Content = $settingsTextBox
    $tabControl.Items.Add($settingsTabItem)
}

