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

# LSA-Dienst stoppen
Stop-Service -Name "LSAService" -Force -ErrorAction SilentlyContinue

# LSI Storage Authority deinstallieren (offline über WMI)
$lsiApp = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*LSI Storage Authority*" }
if ($lsiApp) {
    $lsiApp.Uninstall()
}

# Verknüpfungen und Ordner löschen
Remove-Item -Path "C:\Users\Public\Desktop\Launch LSA.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LSI" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Program Files\LSI" -Recurse -Force -ErrorAction SilentlyContinue
