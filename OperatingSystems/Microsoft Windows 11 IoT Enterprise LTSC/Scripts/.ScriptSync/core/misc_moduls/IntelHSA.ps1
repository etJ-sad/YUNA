	# Intel HSA
	$intelHSAInstalled = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq "AppUp.IntelOptaneMemoryandStorageManagement" }

	$intelHSACheckbox.Content = "Intel Optane Memory and Storage Management"
	$intelHSACheckbox.Margin = "5,60,5,5"
	if ($intelHSAInstalled -ne $null) {
		$intelHSACheckbox.IsChecked = $true	
	}
	$intelHSAPanel.Children.Add($intelHSACheckbox)

	$intelHSAExportButton.Content = " Start Intel Optane Memory and Storage Management "
	$intelHSAExportButton.Margin = "15,58,5,5"
	$intelHSAExportButton.VerticalAlignment = "Top"
	$intelHSAExportButton.IsEnabled = $intelHSAInstalled -ne $null

	$intelHSAExportButton.Add_Click({
		Start-Process "explorer.exe" "shell:appsFolder\AppUp.IntelOptaneMemoryandStorageManagement_8j3eq9eme6ctt!App"
	})

	$intelHSAPanel.Children.Add($intelHSAExportButton)

	$miscGridPanel.Children.Add($intelHSAPanel)
