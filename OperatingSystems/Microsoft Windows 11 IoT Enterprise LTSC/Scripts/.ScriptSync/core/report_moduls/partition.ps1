	# partition
    $partitionCheckbox.Content = "The versions of the Partition have been verified."
    $partitionCheckbox.Margin = "5,135,5,5"
    $partitionPanel.Children.Add($partitionCheckbox)

    $partitionExportButton.Content = "  Export as single JSON  "
    $partitionExportButton.Margin = "33,133,5,5"
	$partitionExportButton.Visibility = 'Hidden'
    $partitionExportButton.VerticalAlignment = "Top"
    $partitionExportButton.Add_Click({
        if ($partitionCheckbox.IsChecked) {
            Export-PartitionTojson
            [System.Windows.MessageBox]::Show("Export complete.", "Partition table", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            Write-Output "partitionCheckbox is not checked"
            [System.Windows.MessageBox]::Show("The Partiton has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }

    })
	$partitionPanel.Children.Add($partitionExportButton)
	$reportGridPanel.Children.Add($partitionPanel)