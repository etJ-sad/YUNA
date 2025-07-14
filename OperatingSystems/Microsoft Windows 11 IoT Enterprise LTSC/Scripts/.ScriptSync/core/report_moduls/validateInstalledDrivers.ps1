    # validateInstalledDrivers
    $validateInstalledDriversCheckbox.Content = "Validate installed Drivers with device mask"
    $validateInstalledDriversCheckbox.Margin = "5,110,5,5"
    $validateInstalledDriversPanel.Children.Add($validateInstalledDriversCheckbox)

    $validateInstalledDriversExportButton.Content = "  Validate  "
    $validateInstalledDriversExportButton.Margin = "61,108,5,5"
	$validateInstalledDriversExportButton.Visibility = 'Hidden'
    $validateInstalledDriversExportButton.VerticalAlignment = "Top"
    $validateInstalledDriversExportButton.Add_Click({
        if ($validateInstalledDriversCheckbox.IsChecked) {
				$path = Split-Path -Path $PSScriptRoot -Parent
				Write-Output $path
				$scriptPath = $path + "\_inputter.ps1"
				Write-Output $scriptPath
				Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        } else {
            Write-Output "validateInstalledDriversCheckbox is not checked"
            [System.Windows.MessageBox]::Show("Installed drivers has not been validated by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
	})
	$validateInstalledDriversPanel.Children.Add($validateInstalledDriversExportButton)
	$reportGridPanel.Children.Add($validateInstalledDriversPanel)