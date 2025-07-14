function Show-ReportTab() {
    $reportTabItem.Header = "Make Report"
	
	# systemFunctionLabel
	$jsonFunctionsLabel.AddText("System Verification")
	$jsonFunctionsLabel.Margin = "5,5,5,5"
	$jsonFunctionsPanel.Children.Add($jsonFunctionsLabel)
	$reportGridPanel.Children.Add($jsonFunctionsPanel)

    # version
    . ".\core\report_moduls\version.ps1"
	
    # installedSoftware
    . ".\core\report_moduls\installedSoftware.ps1"

    # installedDrivers
    . ".\core\report_moduls\installedDrivers.ps1"
	
    # validateInstalledDrivers
    . ".\core\report_moduls\validateInstalledDrivers.ps1"
	
	# partition
	. ".\core\report_moduls\partition.ps1"
	
	# powerSchema
	. ".\core\report_moduls\powerSchema.ps1"
	
	# systemFunctionLabel
	$systemFunctionsLabel.AddText("System Functions")
	$systemFunctionsLabel.Margin = "5,195,5,5"
	$systemFunctionsPanel.Children.Add($systemFunctionsLabel)
	$reportGridPanel.Children.Add($systemFunctionsPanel)
	
	# System Reset
    . ".\core\report_moduls\systemReset.ps1"
	
    # System Recovery
    . ".\core\report_moduls\systemRecovery.ps1"
	
	# Event Log
    . ".\core\report_moduls\eventLog.ps1"
	
	# FullReport
    . ".\core\report_moduls\createFullReport.ps1"
    
    # Append Content
    $reportTabItem.Content = $reportGridPanel
	$tabControl.Items.Add($reportTabItem)
}