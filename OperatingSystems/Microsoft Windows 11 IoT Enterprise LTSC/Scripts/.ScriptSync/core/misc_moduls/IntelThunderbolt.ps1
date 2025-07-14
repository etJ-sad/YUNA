	# Intel VROC SMA
	$intelThunderboltInstalled = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq "AppUp.ThunderboltControlCenter" }

	$intelThunderboltCheckbox.Content = "Intel Thunderbolt Control Center"
	$intelThunderboltCheckbox.Margin = "5,140,5,5"
	if ($intelThunderboltInstalled -ne $null) {
		$intelThunderboltCheckbox.IsChecked = $true
	}
	$intelThunderboltPanel.Children.Add($intelThunderboltCheckbox)

	$intelThunderboltExportButton.Content = " Start Intel Thunderbolt Control Center "
	$intelThunderboltExportButton.Margin = "96,137,5,5"
	$intelThunderboltExportButton.VerticalAlignment = "Top"
	$intelThunderboltExportButton.IsEnabled = $intelThunderboltInstalled -ne $null

	$intelThunderboltExportButton.Add_Click({
		Start-Process "C:\Program Files\WindowsApps\AppUp.ThunderboltControlCenter_1.0.37.0_x64__8j3eq9eme6ctt\ThunderboltControlApp.exe"
	})

	$intelThunderboltPanel.Children.Add($intelThunderboltExportButton)

	$miscGridPanel.Children.Add($intelThunderboltPanel)
