	# powerSchema
    $powerSchemaCheckbox.Content = "The Power Shema have been verified."
    $powerSchemaCheckbox.Margin = "5,160,5,5"
    $powerSchemaPanel.Children.Add($powerSchemaCheckbox)

    $powerSchemaExportButton.Content = "  Export as single JSON  "
    $powerSchemaExportButton.Margin = "87,158,5,5"
	$powerSchemaExportButton.Visibility = 'Hidden'
    $powerSchemaExportButton.VerticalAlignment = "Top"
    $powerSchemaExportButton.Add_Click({
        if ($powerSchemaCheckbox.IsChecked) {
            Export-PowerSchemaToJson
            [System.Windows.MessageBox]::Show("Export complete.", "Power Schema", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            Write-Output "powerSchemaCheckbox is not checked"
            [System.Windows.MessageBox]::Show("The Power Schema has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }

    })
	$powerSchemaPanel.Children.Add($powerSchemaExportButton)
	$reportGridPanel.Children.Add($powerSchemaPanel)