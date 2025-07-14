function Show-ErrorsTab {
    $errorTabItem.Header = "Errors"
	
    $filePath = ".\errors"
    $fileContent = Get-Content -Path $filePath -Raw
    
    $errorTextBox.Text = $fileContent
    
    $errorTabItem.Content = $errorTextBox
    $tabControl.Items.Add($errorTabItem)
}

