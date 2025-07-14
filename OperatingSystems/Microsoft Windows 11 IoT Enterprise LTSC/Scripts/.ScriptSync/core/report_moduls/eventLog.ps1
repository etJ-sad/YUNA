	# Installed Drivers CheckBox
    $eventLogCheckbox.Content = "Event Log have been verified."
    $eventLogCheckbox.Margin = "5,290,5,5"
    $eventLogPanel.Children.Add($eventLogCheckbox)

    $eventLogExportButton.Content = "  Export as single JSON  "
    $eventLogExportButton.Margin = "128,287,5,5"
	$eventLogExportButton.Visibility = 'Hidden'
    $eventLogExportButton.VerticalAlignment = "Top"
    $eventLogExportButton.Add_Click({
        if ($eventLogCheckbox.IsChecked) {
            Export-EventLogToJson
            [System.Windows.MessageBox]::Show("Export complete.", "Event Log", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            Write-Output "eventlogCheckbox is not checked"
            [System.Windows.MessageBox]::Show("Event Log has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }

    })
	$eventLogPanel.Children.Add($eventLogExportButton)
	$reportGridPanel.Children.Add($eventLogPanel)