$apiJson = $null

$apiTabItem = New-Object System.Windows.Controls.TabItem
$apiTextBox = New-Object System.Windows.Controls.TextBox
$apiTextBox.AcceptsReturn = $true
$apiTextBox.AcceptsTab = $true
$apiTextBox.VerticalScrollBarVisibility = 'Visible'
$apiTextBox.HorizontalScrollBarVisibility = 'Auto'
$apiTextBox.IsReadOnly = $true
$apiTextBox.TextWrapping = 'Wrap'

function Show-APITab {
    $apiTabItem.Header = "API"
	
	$apiTextBox.Text = "API TAB:`n" +
							"- Implemet your code in this tab (API.ps1)`n"
    
    $apiTabItem.Content = $apiTextBox
    $tabControl.Items.Add($apiTabItem)
}

