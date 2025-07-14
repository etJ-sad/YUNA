	# Intel IGCC
	$intelIGCCInstalled = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq "AppUp.IntelGraphicsExperience" }

	$intelIGCCCheckbox.Content = "Intel Graphics Command Center"
	$intelIGCCCheckbox.Margin = "5,35,5,5"
	if ($intelIGCCInstalled -ne $null) {
		$intelIGCCCheckbox.IsChecked = $true	
	}
	$intelIGCCPanel.Children.Add($intelIGCCCheckbox)
	
	$intelIGCCExportButton.Content = " Start Intel Graphics Command Center "
	$intelIGCCExportButton.Margin = "100,32,5,5"
	$intelIGCCExportButton.VerticalAlignment = "Top"
	$intelIGCCExportButton.IsEnabled = $intelIGCCInstalled -ne $null

	$intelIGCCExportButton.Add_Click({
		Start-Process "explorer.exe" "shell:appsFolder\AppUp.IntelGraphicsExperience_8j3eq9eme6ctt!App"
	})

	$intelIGCCPanel.Children.Add($intelIGCCExportButton)

	$miscGridPanel.Children.Add($intelIGCCPanel)
