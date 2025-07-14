    # installedDrivers
    $installedDriversCheckbox.Content = "Versions of installed drivers have been verified."
    $installedDriversCheckbox.Margin = "5,85,5,5"
    $installedDriversPanel.Children.Add($installedDriversCheckbox)

    $installedDriversExportButton.Content = "  Export as single JSON  "
    $installedDriversExportButton.Margin = "37,83,5,5"
	$installedDriversExportButton.Visibility = 'Hidden'
    $installedDriversExportButton.VerticalAlignment = "Top"
    $installedDriversExportButton.Add_Click({
        if ($installedDriversCheckbox.IsChecked) {
            Export-InstalledDriversTojson
            [System.Windows.MessageBox]::Show("Export complete.", "Installed drivers", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            Write-Output "installedDriversCheckbox is not checked"
            [System.Windows.MessageBox]::Show("Installed drivers has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }

    })
	$installedDriversPanel.Children.Add($installedDriversExportButton)
	$reportGridPanel.Children.Add($installedDriversPanel)