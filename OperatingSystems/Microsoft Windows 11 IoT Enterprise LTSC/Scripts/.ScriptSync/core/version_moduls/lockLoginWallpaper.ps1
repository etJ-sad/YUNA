	# LockLoginWallpaper
	$osLockLoginWallpaper = $versionTable.NewRow()
	$osLockLoginWallpaper["About"] = "LockLoginWallpaper"

	$file1Path = "C:\Windows\Web\SIMATIC\SIMATIC_IPC_Device.jpg"
	$file2Path = ".\_validation\.lock_login_image"

	$fcResult = cmd /c fc /B $file1Path $file2Path
	if ($fcResult -match "no differences encountered") {
		$osLockLoginWallpaper["Value"] = $file1Path
		$osLockLoginWallpaper["Status"] = "pass"
	} else {
		if (Test-Path ".\_validation\.lock_login_image") { 
			$osLockLoginWallpaper["Value"] = $file1Path
			$osLockLoginWallpaper["Status"] = "fail"
			$message = "OS Background Wallpaper Comparison: => fail: The files are different. `nFirst File: $file1Path `nSecond File: $file2Path `n" 
			Write-Output $message | Out-File .\errors -Append
		} else {
			$osLockLoginWallpaper["Value"] = $file1Path
			$osLockLoginWallpaper["Status"] = "missing"
			Write-Output "LockLoginWallpaper => missing: validation file was not detected: .\_validation\.lock_login_image `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($osLockLoginWallpaper)