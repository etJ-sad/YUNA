function Show-MiscTab() {
    $miscTabItem.Header = "Misc"
	$miscGridPanel.VerticalAlignment = "Top"
		
	# UWP Apps
	$uwpAppsLabel.AddText("UWP Apps")
	$uwpAppsLabel.Margin = "5,5,5,5"
	$uwpAppsPanel.Children.Add($uwpAppsLabel)
	$miscGridPanel.Children.Add($uwpAppsPanel)	
		
	# IntelIGCC
	. ".\core\misc_moduls\IntelIGCC.ps1"
	
	# IntelHSA 
	. ".\core\misc_moduls\IntelHSA.ps1"
	
	# IntelIMSS 
	. ".\core\misc_moduls\IntelIMSS.ps1"
	
	# IntelVROCSMA 
	. ".\core\misc_moduls\IntelVROCSMA.ps1"

	# IntelThunderbolt
	. ".\core\misc_moduls\IntelThunderbolt.ps1"
	
	# NvidiaControlPanel
	. ".\core\misc_moduls\NvidiaControlPanel.ps1"
	
	# RealtekAudioConsole
	. ".\core\misc_moduls\RealtekAudioConsole.ps1"
	
	# UWP Apps
	$portsLabel.AddText("Network Ports")
	$portsLabel.Margin = "5,215,5,5"
	$portsPanel.Children.Add($portsLabel)
	$miscGridPanel.Children.Add($portsPanel)	
	
	# Port 135
	. ".\core\misc_moduls\Port135.ps1"
	
	# Port 445
	. ".\core\misc_moduls\Port445.ps1"
	
	# Port 63105
	. ".\core\misc_moduls\Port63105.ps1"
	
    # Append Content
	$miscTabItem.Content = $miscGridPanel
	$tabControl.Items.Add($miscTabItem)
}