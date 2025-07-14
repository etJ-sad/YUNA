	# Realtek Audio Console
	$realtekAudioConsoleInstalled = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq "RealtekSemiconductorCorp.RealtekAudioControl" }

	$realtekAudioConsoleCheckbox.Content = "Realtek Audio Console"
	$realtekAudioConsoleCheckbox.Margin = "5,194,5,5"
	if ($realtekAudioConsoleInstalled -ne $null) {
			$realtekAudioConsoleCheckbox.IsChecked = $true
	}
	$realtekAudioConsolePanel.Children.Add($realtekAudioConsoleCheckbox)

	$realtekAudioConsoleExportButton.Content = " Start Realtek Audio Console "
	$realtekAudioConsoleExportButton.Margin = "149,192,5,5"
	$realtekAudioConsoleExportButton.VerticalAlignment = "Top"
	$realtekAudioConsoleExportButton.IsEnabled = $realtekAudioConsoleInstalled -ne $null

	$realtekAudioConsoleExportButton.Add_Click({
		Start-Process "explorer.exe" "shell:appsFolder\RealtekSemiconductorCorp.RealtekAudioControl_dt26b99r8h8gj!App"
	})

	$realtekAudioConsolePanel.Children.Add($realtekAudioConsoleExportButton)

	$miscGridPanel.Children.Add($realtekAudioConsolePanel)
