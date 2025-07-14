	# NVIDIA Control Panel
	$nvidiaControlPanelInstalled = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq "NVIDIACorp.NVIDIAControlPanel" }

	$nvidiaControlPanelCheckbox.Content = "NVIDIA Control Panel"
	$nvidiaControlPanelCheckbox.Margin = "5,167,5,5"
	if ($nvidiaControlPanelInstalled -ne $null) {
			$nvidiaControlPanelCheckbox.IsChecked = $true
	}
	$nvidiaControlPanelPanel.Children.Add($nvidiaControlPanelCheckbox)

	$nvidiaControlPanelExportButton.Content = " Start NVIDIA Control Panel "
	$nvidiaControlPanelExportButton.Margin = "155,165,5,5"
	$nvidiaControlPanelExportButton.VerticalAlignment = "Top"
	$nvidiaControlPanelExportButton.IsEnabled = $nvidiaControlPanelInstalled -ne $null

	$nvidiaControlPanelExportButton.Add_Click({
		Start-Process "C:\Program Files\WindowsApps\NVIDIACorp.NVIDIAControlPanel_8.1.967.0_x64__56jybvy8sckqj\nvcplui.exe"
	})

	$nvidiaControlPanelPanel.Children.Add($nvidiaControlPanelExportButton)

	$miscGridPanel.Children.Add($nvidiaControlPanelPanel)
