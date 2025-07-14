# version
$versionAsJSON = $null
$versionTable = New-Object System.Data.DataTable
$versionTab = New-Object System.Windows.Controls.TabItem
$versionTabGrid = New-Object System.Windows.Controls.DataGrid
$versionTabGrid.AutoGenerateColumns = $true
$versionTabGrid.HorizontalScrollBarVisibility = "Disabled"
#$versionTabGrid.VerticalScrollBarVisibility = "Disabled" 
#$versionTabGrid.ColumnWidth = "*"

$jsonPath = 'C:\Version.json'
$jsonContent = Get-Content -Path $jsonPath | ConvertFrom-Json

# installedSoftware
$installedSoftwareJson = $null
$installedSoftwareTabItem = New-Object System.Windows.Controls.TabItem
$installedSoftwareDataGrid = New-Object System.Windows.Controls.DataGrid
$installedSoftwareDataTable = New-Object System.Data.DataTable
$installedSoftwareDataGrid.AutoGenerateColumns = $true
$installedSoftwareDataGrid.ColumnWidth = "*"

# installedDrivers
$installedDriversJson = $null
$installedDriversTabItem = New-Object System.Windows.Controls.TabItem
$installedDriversDataGrid = New-Object System.Windows.Controls.DataGrid
$installedDriversDataTable = New-Object System.Data.DataTable
$installedDriversDataGrid.AutoGenerateColumns = $true
$installedDriversDataGrid.ColumnWidth = "*"

# powerSchema
$powerSchemaJson = $null
$powerSchemaTabItem = New-Object System.Windows.Controls.TabItem
$powerSchemaDataGrid = New-Object System.Windows.Controls.DataGrid
$powerSchemaTable = New-Object System.Data.DataTable
$powerSchemaDataGrid.AutoGenerateColumns = $true
$powerSchemaDataGrid.HorizontalScrollBarVisibility = "Disabled" 
#$powerSchemaDataGrid.VerticalScrollBarVisibility = "Disabled" 
#$powerSchemaDataGrid.ColumnWidth = "*"

# partition
$partitionJson = $null
$partitionTable = New-Object System.Data.DataTable
$partitionTabItem = New-Object System.Windows.Controls.TabItem
$partitionDataGrid = New-Object System.Windows.Controls.DataGrid
$partitionDataGrid.AutoGenerateColumns = $true
$partitionDataGrid.HorizontalScrollBarVisibility = "Disabled" 
#$partitionDataGrid.VerticalScrollBarVisibility = "Disabled" 
#$partitionDataGrid.ColumnWidth = "*"

# eventLog
$eventLogJson = $null
$eventLogTabItem = New-Object System.Windows.Controls.TabItem
$eventLogDataGrid = New-Object System.Windows.Controls.DataGrid
$eventLogTable = New-Object System.Data.DataTable
$eventLogDataGrid.AutoGenerateColumns = $true
$eventLogDataGrid.HorizontalScrollBarVisibility = "Disabled" 
#$eventLogDataGrid.VerticalScrollBarVisibility = "Disabled" 
#$eventLogDataGrid.ColumnWidth = "*"

# report
$reportTabItem = New-Object System.Windows.Controls.TabItem
$reportGridPanel = New-Object System.Windows.Controls.Grid

$jsonFunctionsLabel = New-Object System.Windows.Controls.Label
$jsonFunctionsPanel =  New-Object System.Windows.Controls.StackPanel
$jsonFunctionsPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal

$versionCheckbox = New-Object System.Windows.Controls.CheckBox
$versionPanel =  New-Object System.Windows.Controls.StackPanel
$versionPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$versionExportButton = New-Object System.Windows.Controls.Button

$installedSoftwareCheckbox = New-Object System.Windows.Controls.CheckBox
$installedSoftwarePanel =  New-Object System.Windows.Controls.StackPanel
$installedSoftwarePanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$installedSoftwareExportButton = New-Object System.Windows.Controls.Button

$installedDriversCheckbox = New-Object System.Windows.Controls.CheckBox
$installedDriversPanel =  New-Object System.Windows.Controls.StackPanel
$installedDriversPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$installedDriversExportButton = New-Object System.Windows.Controls.Button

$validateInstalledDriversCheckbox = New-Object System.Windows.Controls.CheckBox
$validateInstalledDriversPanel =  New-Object System.Windows.Controls.StackPanel
$validateInstalledDriversPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$validateInstalledDriversExportButton = New-Object System.Windows.Controls.Button

$partitionCheckbox = New-Object System.Windows.Controls.CheckBox
$partitionPanel =  New-Object System.Windows.Controls.StackPanel
$partitionPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$partitionExportButton = New-Object System.Windows.Controls.Button

$powerSchemaCheckbox = New-Object System.Windows.Controls.CheckBox
$powerSchemaPanel =  New-Object System.Windows.Controls.StackPanel
$powerSchemaPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$powerSchemaExportButton = New-Object System.Windows.Controls.Button

$systemFunctionsLabel = New-Object System.Windows.Controls.Label
$systemFunctionsPanel =  New-Object System.Windows.Controls.StackPanel
$systemFunctionsPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal

$systemResetCheckbox = New-Object System.Windows.Controls.CheckBox
$systemResetPanel =  New-Object System.Windows.Controls.StackPanel
$systemResetPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$systemResetExportButton = New-Object System.Windows.Controls.Button

$systemRecoveryMenuCheckbox = New-Object System.Windows.Controls.CheckBox
$systemRecoveryMenuPanel =  New-Object System.Windows.Controls.StackPanel
$systemRecoveryMenuPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$systemRecoveryMenuExportButton = New-Object System.Windows.Controls.Button

$eventLogCheckbox = New-Object System.Windows.Controls.CheckBox
$eventLogPanel =  New-Object System.Windows.Controls.StackPanel
$eventLogPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$eventLogExportButton = New-Object System.Windows.Controls.Button

$createFullReportjsonfileButton = New-Object System.Windows.Controls.Button

# MiscTab
$miscTabItem = New-Object System.Windows.Controls.TabItem
$miscGridPanel = New-Object System.Windows.Controls.Grid

$uwpAppsLabel = New-Object System.Windows.Controls.Label
$uwpAppsPanel =  New-Object System.Windows.Controls.StackPanel
$uwpAppsPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal

$intelIGCCLabel = New-Object System.Windows.Controls.Label
$intelIGCCCheckbox = New-Object System.Windows.Controls.CheckBox
$intelIGCCPanel = New-Object System.Windows.Controls.StackPanel
$intelIGCCPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$intelIGCCExportButton = New-Object System.Windows.Controls.Button

$intelHSALabel = New-Object System.Windows.Controls.Label
$intelHSACheckbox = New-Object System.Windows.Controls.CheckBox
$intelHSAPanel = New-Object System.Windows.Controls.StackPanel
$intelHSAPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$intelHSAExportButton = New-Object System.Windows.Controls.Button

$intelIMSSLabel = New-Object System.Windows.Controls.Label
$intelIMSSCheckbox = New-Object System.Windows.Controls.CheckBox
$intelIMSSPanel = New-Object System.Windows.Controls.StackPanel
$intelIMSSPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$intelIMSSExportButton = New-Object System.Windows.Controls.Button

$intelVROCSMALabel = New-Object System.Windows.Controls.Label
$intelVROCSMACheckbox = New-Object System.Windows.Controls.CheckBox
$intelVROCSMAPanel = New-Object System.Windows.Controls.StackPanel
$intelVROCSMAPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$intelVROCSMAExportButton = New-Object System.Windows.Controls.Button

$intelThunderboltLabel = New-Object System.Windows.Controls.Label
$intelThunderboltCheckbox = New-Object System.Windows.Controls.CheckBox
$intelThunderboltPanel = New-Object System.Windows.Controls.StackPanel
$intelThunderboltPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$intelThunderboltExportButton = New-Object System.Windows.Controls.Button

$nvidiaControlPanelLabel = New-Object System.Windows.Controls.Label
$nvidiaControlPanelCheckbox = New-Object System.Windows.Controls.CheckBox
$nvidiaControlPanelPanel = New-Object System.Windows.Controls.StackPanel
$nvidiaControlPanelPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$nvidiaControlPanelExportButton = New-Object System.Windows.Controls.Button

$realtekAudioConsoleLabel = New-Object System.Windows.Controls.Label
$realtekAudioConsoleCheckbox = New-Object System.Windows.Controls.CheckBox
$realtekAudioConsolePanel = New-Object System.Windows.Controls.StackPanel
$realtekAudioConsolePanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$realtekAudioConsoleExportButton = New-Object System.Windows.Controls.Button

$portsLabel = New-Object System.Windows.Controls.Label
$portsPanel =  New-Object System.Windows.Controls.StackPanel
$portsPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal

$port445Label = New-Object System.Windows.Controls.Label
$port445Checkbox = New-Object System.Windows.Controls.CheckBox
$port445Panel = New-Object System.Windows.Controls.StackPanel
$port445Panel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$port445ExportButton = New-Object System.Windows.Controls.Button

$port135Label = New-Object System.Windows.Controls.Label
$port135Checkbox = New-Object System.Windows.Controls.CheckBox
$port135Panel = New-Object System.Windows.Controls.StackPanel
$port135Panel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$port135ExportButton = New-Object System.Windows.Controls.Button

$port63105Label = New-Object System.Windows.Controls.Label
$port63105Checkbox = New-Object System.Windows.Controls.CheckBox
$port63105Panel = New-Object System.Windows.Controls.StackPanel
$port63105Panel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
$port63105ExportButton = New-Object System.Windows.Controls.Button

# errors
$errorJson = $null
$errorTabItem = New-Object System.Windows.Controls.TabItem
$errorTextBox = New-Object System.Windows.Controls.TextBox
$errorTextBox.AcceptsReturn = $true
$errorTextBox.AcceptsTab = $true
$errorTextBox.VerticalScrollBarVisibility = 'Visible'
$errorTextBox.HorizontalScrollBarVisibility = 'Auto'
$errorTextBox.IsReadOnly = $true
$errorTextBox.TextWrapping = 'Wrap'

# status
$cellTemplate = 
@"
	<DataTemplate xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'>
		<TextBlock Text='{Binding Status}'>
			<TextBlock.Style>
				<Style TargetType='TextBlock'>
					<Style.Triggers>
						<DataTrigger Binding='{Binding Status}' Value='fail'>
							<Setter Property='Background' Value='Red'/>
						</DataTrigger>
						<DataTrigger Binding='{Binding Status}' Value='pass'>
							<Setter Property='Background' Value='#FFC4FFA6'/>
						</DataTrigger>
						<DataTrigger Binding='{Binding Status}' Value='missing'>
							<Setter Property='Background' Value='#FFA500'/>
						</DataTrigger>
					</Style.Triggers>
				</Style>
			</TextBlock.Style>
		</TextBlock>
	</DataTemplate>
"@