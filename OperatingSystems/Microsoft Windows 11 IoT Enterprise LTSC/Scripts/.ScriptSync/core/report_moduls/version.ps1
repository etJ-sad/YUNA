    # version
    $versionCheckbox.Content = "Windows basic setting of image has been verified."
    $versionCheckbox.Margin = "5,35,5,5"
    $versionPanel.Children.Add($versionCheckbox)
	
	$versionExportButton.Content = "  Export as single JSON  "
    $versionExportButton.Margin = "20,32,5,5"
	$versionExportButton.Visibility = 'Hidden'
    $versionExportButton.VerticalAlignment = "Top"
    $versionExportButton.Add_Click({
        if ($versionCheckbox.IsChecked) {
            Export-VersionTojson
            [System.Windows.MessageBox]::Show("Export complete.", "Windows version", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            Write-Output "versionCheckbox is not checked"
            [System.Windows.MessageBox]::Show("The Windows-Image has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }

    })
	$versionPanel.Children.Add($versionExportButton)
	$reportGridPanel.Children.Add($versionPanel)