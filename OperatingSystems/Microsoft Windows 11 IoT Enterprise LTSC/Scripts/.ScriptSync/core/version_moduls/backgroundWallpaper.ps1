	# backgroundWallpaper
	$osBackgroundWallpaper = $versionTable.NewRow()
	$osBackgroundWallpaper["About"] = "BackgroundWallpaper"

	$file1Path = "C:\Windows\Web\SIMATIC\SIMATIC_IPC_Background.jpg"
	$file2Path = ".\_validation\.desktop_image"

	$fcResult = cmd /c fc /B $file1Path $file2Path
	if ($fcResult -match "no differences encountered") {
		$osBackgroundWallpaper["Value"] = $file1Path
		$osBackgroundWallpaper["Status"] = "pass"
	} else {
		if (Test-Path ".\_validation\.desktop_image") { 
			$osBackgroundWallpaper["Value"] = $file1Path
			$osBackgroundWallpaper["Status"] = "fail"
			$message = "OS Background Wallpaper Comparison: => fail: The files are different. `nFirst File: $file1Path `nSecond File: $file2Path `n" 
			Write-Output $message | Out-File .\errors -Append
		} else {
			$osBackgroundWallpaper["Value"] = $file1Path
			$osBackgroundWallpaper["Status"] = "missing"
			Write-Output "BackgroundWallpaper => missing: validation file was not detected: .\_validation\.desktop_image `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($osBackgroundWallpaper)