Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'
function Hide-ConsoleWindow {
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 0)
}

Hide-ConsoleWindow

Stop-Service -Name "LSAService" -Force

$appName = (Get-Package | Where-Object { $_.Name -like "*LSI Storage Authority*" }).Name
if ($appName) {
    Uninstall-Package -Name $appName -Force
}

Remove-Item -Path "C:\Users\Public\Desktop\Launch LSA.lnk" -Recurse 
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LSI" -Recurse 
Remove-Item -Path "C:\Program Files\LSI" -Recurse 
