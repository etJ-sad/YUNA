function Show-PartitionTab(){
	
    $partitionTabItem.Header = "Partition"
        
    $partitionDataGrid.VerticalAlignment = "Top"

    $partitionTable.Columns.Add("DriveLetter")
    $partitionTable.Columns.Add("VolumeName")
    $partitionTable.Columns.Add("PartitionTable")
    $partitionTable.Columns.Add("SizeGB")
    $partitionTable.Columns.Add("FreeSpaceGB")
    $partitionTable.Columns.Add("Status")

	$lastDiskNumber = $null
	
	$allowedPartitionLabels = Get-Content ".\_validation\.partitionLabels.json" -Raw | ConvertFrom-Json
	$allowedPartitionTable = Get-Content ".\_validation\.partitionTable.json" -Raw | ConvertFrom-Json
	
	Get-Partition | ForEach-Object {
		$Volume = Get-Volume -Partition $_
		$Disk = Get-Disk -Number $_.DiskNumber

		if ($_.DriveLetter -ne "D" -and $_.DriveLetter -ne "C") {
			return 
		}
		
		$Row = $partitionTable.NewRow()

		$Row["DriveLetter"] = $_.DriveLetter
		$Row["VolumeName"] = $Volume.FileSystemLabel
		$Row["PartitionTable"] = $Disk.PartitionStyle

		# Label	
		if ($Volume.DriveLetter -eq "C") {
			if ($Volume.FileSystemLabel -eq $allowedPartitionLabels.C) {
				$Row["Status"] = "pass"
			} else {
				if (Test-Path ".\_validation\.partitionLabels.json") { 
					$Row["Status"] = "fail"
					$Row["VolumeName"] = "$($Volume.FileSystemLabel) -> fail"
					Write-Output "VolumeName: => fail: $Volume.FileSystemLabel `nExpected: $allowedPartitionLabels.C `n" | Out-File .\errors -Append
				} else {
					$Row["Status"] = "missing"
					Write-Output "VolumeName: => missing: validation file was not detected: .\_validation\.partitionLabels.json `n" | Out-File .\errors -Append
				}
			}
		} 
		elseif ($Volume.DriveLetter -eq "D") {
			if ($Volume.FileSystemLabel -eq $allowedPartitionLabels.D) {
				$Row["Status"] = "pass"
			} else {
				if (Test-Path ".\_validation\.partitionLabels.json") { 
					$Row["Status"] = "fail"
					$Row["VolumeName"] = "$($Volume.FileSystemLabel) -> fail"
					Write-Output "VolumeName: => fail: $Volume.FileSystemLabel `nExpected: $allowedPartitionLabels.D `n" | Out-File .\errors -Append
				} else {
					$Row["Status"] = "missing"
					Write-Output "VolumeName: => missing: validation file was not detected: .\_validation\.partitionLabels.json `n" | Out-File .\errors -Append
				}
			}
		} 
		else {
			$Row["Status"] = "unknown"
		}
		
		#Volume
		if ($Disk.PartitionStyle -eq $allowedPartitionTable.GPT) {
			$Row["Status"] = "pass"
		} else {
			if (Test-Path ".\_validation\.partitionTable.json") { 
				$Row["Status"] = "fail"
				$Row["PartitionTable"] = "$($Disk.PartitionStyle) -> fail"
				Write-Output "PartitionTable: => fail: $Disk.PartitionStyle `nExpected: $allowedPartitionTable.GPT `n" | Out-File .\errors -Append
			} else {
				$Row["Status"] = "missing"
				Write-Output "PartitionTable: => missing: validation file was not detected: .\_validation\.partitionTable.json `n" | Out-File .\errors -Append
			}	
		} 
		
		# DriverSize
		function Get-DriveWithWindowsFolder {
			Param (
				[string]$DriveLetter
			)

			$WindowsFolder = Join-Path -Path $DriveLetter -ChildPath 'Windows'
			if (Test-Path $WindowsFolder -PathType Container) {
				return $DriveLetter
			}
		}

		$drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
		$windowsDrive = $drives | ForEach-Object { Get-DriveWithWindowsFolder -DriveLetter $_ }

		if ([math]::Round($_.Size / 1GB, 2) -lt 1) {
			$sizeInGB = [math]::Round($_.Size / 1GB, 2)
			$fullDriveSpace = "{0:N2} MB" -f ($_.Size / 1MB)
		} else {
			$sizeInGB = [math]::Round($_.Size / 1GB, 2)
			$fullDriveSpace = "{0:N2} GB" -f ($sizeInGB)
		}
		
		$sizeInGB = $sizeInGB -replace ",.*", ""
		$sizeInGB = [int]$sizeInGB
		$Row["SizeGB"] = $fullDriveSpace

		if ([math]::Round($Volume.SizeRemaining / 1GB, 2) -lt 1) {
			$freeDriveSpace = "{0:N2} MB" -f ($Volume.SizeRemaining / 1MB)
			$Row["FreeSpaceGB"] = $freeDriveSpace
		} else {
			$freeDriveSpace = "{0:N2} GB" -f ($Volume.SizeRemaining / 1GB)
			$Row["FreeSpaceGB"] = $freeDriveSpace
		}

		if (-not $windowsDrive) {
			Write-Output "Windows folder not found on any drive."
			return
		}

		$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$windowsDrive'"
		$diskSizeBytes = $disk.Size
		$diskSizeMB = [math]::Round($diskSizeBytes / 1MB)

		$partitionCSizeBytes = $disk.Size
		$partitionCSizeMB = [math]::Round($partitionCSizeBytes / 1MB)

		$matched = $false

		if ($_.DriveLetter -eq "D"){
			#NULL
		} else {
			$jsonConfigPath = ".\_validation\.partitionSize.json"
			if (Test-Path $jsonConfigPath) {
				$jsonConfig = Get-Content -Raw -Path $jsonConfigPath | ConvertFrom-Json
			} else {
				$Row["Status"] = "missing"
				Write-Output "PartitionSize: => missing: validation file was not detected: $jsonConfigPath `n" | Out-File .\errors -Append
				exit 1
			}

			# Get size of Drive 0 in GB
			$drive0 = Get-WmiObject Win32_DiskDrive | Select-Object -First 1
			$drive0SizeGB = [math]::Round($drive0.Size / 1GB, 0)

			# Get current size of Partition C: in GB
			$partitionC = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq 'C:' }
			$currentCSizeGB = [math]::Round($partitionC.Size / 1GB, 2)

			# Determine expected partition size based on drive size from JSON configuration
			$expectedCSizeGB = 0

			foreach ($partition in $jsonConfig.partitions) {
				if ($drive0SizeGB -le $partition.drive_size_max) {
					$expectedCSizeGB = $partition.partition_size_gb
					break
				}
			}

			if ($expectedCSizeGB -eq 0) {
				# Default case if no matching configuration found
				$expectedCSizeGB = 240  # Default value if no match is found
			}

			# Output drive 0 size and current/expected partition C size
			Write-Output "Drive 0 Size: $drive0SizeGB GB"
			Write-Output "Current Partition C: Size: $currentCSizeGB GB"
			Write-Output "Expected Partition C: Size: $expectedCSizeGB GB"

			# Output status based on comparison
			if ($currentCSizeGB -eq $expectedCSizeGB) {
				$Row["Status"] = "pass"
			} else {
				$Row["SizeGB"] = "$drive0SizeGB -> fail"
				$Row["Status"] = "fail"
				Write-Output "PartitionSize: => fail: $drive0SizeGB `nExpected: $expectedCSizeGB `n" | Out-File .\errors -Append
			}


		}

		$partitionTable.Rows.Add($Row)
		$lastDiskNumber = $_.DiskNumber
	}
	
	<#
	$partitionDataGrid.add_LoadingRow({
        param($sender, $e)
        $row = $e.Row
        $status = $row.DataContext.Status
        if ($status -eq "fail") {
            $row.Background = "Red"
        } elseif ($status -eq "pass") {
            $row.Background = "#FFC4FFA6"
        }
    })
	#>
	
    $partitionDataGrid.ItemsSource = $partitionTable.DefaultView
	
	$partitionDataGrid.add_AutoGeneratedColumns({
		param($sender, $e)
		if ($sender.Columns.Count -ge 5) {
				$sender.Columns[0].Width = 75
				$sender.Columns[1].Width = 75
				$sender.Columns[2].Width = 185
				$sender.Columns[3].Width = 175
				$sender.Columns[4].Width = 175
				$sender.Columns[5].Width = 185
		}
	})
	
	$partitionStatusColumn = New-Object Windows.Controls.DataGridTemplateColumn
	$partitionStatusColumn.Header = "Status"
	$partitionStatusColumn.CellTemplate = [Windows.Markup.XamlReader]::Parse($cellTemplate)
	
	$partitionDataGrid.Columns.Add($partitionStatusColumn)
	
    # Append Content
    $partitionTabItem.Content = $partitionDataGrid
    $tabControl.Items.Add($partitionTabItem)
}

function Export-PartitionToJson {
    param(
        [bool]$fullReport = $false
    )

	$partitionJson = @()
	
	$PartitionTable.Rows | ForEach-Object {

		$partitionInfo = @{
			"DriveLetter" = $_["DriveLetter"]
			"VolumeName" = $_["VolumeName"]
			"PartitionTable" = $_["PartitionTable"]
			"Size_GB" = $_["SizeGB"]
			"FreeSpace_GB" = $_["FreeSpaceGB"]
			"Status" = $_["Status"]
		}

		$partitionJson += $partitionInfo
	}
	
	$jsonOutput = $partitionJson | ConvertTo-Json -Depth 2
	$jsonOutput | Out-File -Encoding UTF8 -FilePath ".\output\_partition.json"	
}