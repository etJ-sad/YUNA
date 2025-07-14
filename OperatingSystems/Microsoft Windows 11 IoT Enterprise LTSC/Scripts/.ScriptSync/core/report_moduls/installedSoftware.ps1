    # installedSoftware
    $installedSoftwareCheckbox.Content = "Versions of installed software have been verified."
    $installedSoftwareCheckbox.Margin = "5,60,5,5"
    $installedSoftwarePanel.Children.Add($installedSoftwareCheckbox)
    $installedSoftwareExportButton.Content = "  Export as single JSON  "
    $installedSoftwareExportButton.Margin = "27,58,5,5"
	$installedSoftwareExportButton.Visibility = 'Hidden'
    $installedSoftwareExportButton.VerticalAlignment = "Top"
    $installedSoftwareExportButton.Add_Click({
        if ($installedSoftwareCheckbox.IsChecked) {
            Export-InstalledSoftwareTojson
            [System.Windows.MessageBox]::Show("Export complete.", "Installed software", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            Write-Output "installedSoftwareCheckbox is not checked"
            [System.Windows.MessageBox]::Show("Installed software has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }

    })
	$installedSoftwarePanel.Children.Add($installedSoftwareExportButton)
	$reportGridPanel.Children.Add($installedSoftwarePanel)