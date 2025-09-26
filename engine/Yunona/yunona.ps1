# Yunona - Image Slideshow with Progress Tracking and Logging
# PowerShell 5 compatible with WPF GUI - NO BACKGROUND TERMINAL VERSION

# Hide PowerShell console window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) 

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing

#Async device register
Get-PnpDevice | Where-Object {$_.ConfigManagerErrorCode -ne 0} | ForEach-Object { Start-Job -ScriptBlock { param($InstanceId) Disable-PnpDevice -InstanceId $InstanceId -Confirm:$false; Enable-PnpDevice -InstanceId $InstanceId -Confirm:$false } -ArgumentList $_.InstanceId }

# Global variables
$script:currentImageIndex = 0
$script:images = @()
$script:slideTimer = $null
$script:window = $null
$script:allowClose = $false
$script:logFile = ""
$script:pendingBitmap = $null
$script:allTasksCompleted = $false

# Get the script's directory dynamically
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $SCRIPT_DIR) {
    $SCRIPT_DIR = Get-Location
}

# Configuration with absolute paths
$SLIDE_INTERVAL = 5200 # 5.2 seconds
$IMAGES_FOLDER = Join-Path $SCRIPT_DIR "blob"
$CONFIG_PATH = Join-Path $SCRIPT_DIR "config.json"
$JOB_MANIFEST_PATH = Join-Path $SCRIPT_DIR "job_manifest.json"
$INIT_SCRIPT = "C:\Users\Public\initializationComplete.ps1"
$SCRIPTS_FOLDER = Join-Path $SCRIPT_DIR "scripts"  # New folder for PowerShell scripts

# Animation settings
$USE_ANIMATIONS = $true
$ANIMATION_TYPE = "fade"
$ANIMATION_DURATION = 800 # 0.8 seconds animation

# Window size configuration
$IMAGE_WIDTH = 960
$IMAGE_HEIGHT = 540
$STATUS_HEIGHT = 50    # New: Height for status label
$PROGRESS_HEIGHT = 90
$WINDOW_WIDTH = $IMAGE_WIDTH
$WINDOW_HEIGHT = $IMAGE_HEIGHT + $STATUS_HEIGHT + $PROGRESS_HEIGHT

# Logging functions
function Initialize-LogFile {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:logFile = Join-Path $SCRIPT_DIR "Yunona_$timestamp.log"
    try {
        "=== Yunona Log Started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $script:logFile -Encoding UTF8
        Write-LogMessage "INFO" "Log file initialized: $script:logFile"
        return $true
    }
    catch {
        # Silently fail if log file cannot be created
        return $false
    }
}

function Write-LogMessage {
    param(
        [string]$Level = "INFO",
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Only write to log file (no console output since it's hidden)
    if ($script:logFile -and (Test-Path (Split-Path $script:logFile -Parent))) {
        try {
            $logEntry | Out-File -FilePath $script:logFile -Append -Encoding UTF8
        }
        catch {
            # Ignore log file errors
        }
    }
}

function Update-ProgressDisplay {
    if ($script:window -and $script:window.IsLoaded) {
        # Check for completion flag file
        $completionFlagPath = Join-Path $SCRIPT_DIR "yunona_completion.flag"
        if (Test-Path $completionFlagPath) {
            Write-LogMessage "INFO" "Background processing completed - detected completion flag"
            # Clean up flag file
            try {
                Remove-Item $completionFlagPath -Force -ErrorAction SilentlyContinue
            } catch {}
            
            $script:allTasksCompleted = $true
            Show-CompletionMessage
            return
        }
    }
}

function Show-CompletionMessage {
    # Stop timers first
    if ($script:slideTimer) { 
        $script:slideTimer.Stop() 
        Write-LogMessage "INFO" "Slideshow timer stopped for completion message"
    }
    
    Write-LogMessage "INFO" "Showing installation completion message"
    
    $script:window.Dispatcher.Invoke([System.Action]{
        try {
            # Hide the image area
            $imageHost = $script:window.FindName("ImageHost")
            if ($imageHost) {
                $imageHost.Visibility = [System.Windows.Visibility]::Hidden
                Write-LogMessage "INFO" "Image host hidden successfully"
            }
            
            # Hide progress container
            $progressContainer = $script:window.FindName("ProgressContainer")
            if ($progressContainer) {
                $progressContainer.Visibility = [System.Windows.Visibility]::Hidden
                Write-LogMessage "INFO" "Progress container hidden"
            }
            
            # Hide status container
            $statusContainer = $script:window.FindName("StatusContainer")
            if ($statusContainer) {
                $statusContainer.Visibility = [System.Windows.Visibility]::Hidden
                Write-LogMessage "INFO" "Status container hidden"
            }
            
            # Create completion message overlay
            $mainGrid = $script:window.Content
            if ($mainGrid -and $mainGrid -is [System.Windows.Controls.Grid]) {
                $completionGrid = New-Object System.Windows.Controls.Grid
                $completionGrid.Background = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Colors]::Black)
                
                $completionText = New-Object System.Windows.Controls.TextBlock
                $completionText.Text = "Installation Complete`nWindows is ready to use"
                $completionText.Foreground = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Colors]::White)
                $completionText.FontSize = 32
                $completionText.FontWeight = "Bold"
                $completionText.HorizontalAlignment = "Center"
                $completionText.VerticalAlignment = "Center"
                $completionText.TextAlignment = "Center"
                
                $completionGrid.Children.Add($completionText)
                [System.Windows.Controls.Grid]::SetRowSpan($completionGrid, 3)  # Span all three rows
                $mainGrid.Children.Add($completionGrid)
                Write-LogMessage "INFO" "Completion overlay added successfully"
            }
            
        }
        catch {
            Write-LogMessage "ERROR" "Error showing completion message: $($_.Exception.Message)"
        }
    })
    
    # Start 3-second completion timer
    $completionTimer = New-Object System.Windows.Threading.DispatcherTimer
    $completionTimer.Interval = [TimeSpan]::FromMilliseconds(3000)
    $completionTimer.Add_Tick({
        Write-LogMessage "INFO" "Completion message timeout - closing application"
        $script:allowClose = $true
        $script:window.Close()
    })
    $completionTimer.Start()
    Write-LogMessage "INFO" "Completion timer started - application will close in 3 seconds"
}

function Start-BackgroundProcessing {
    Write-LogMessage "INFO" "=== Starting Background Processing ==="
    
    # Create background processing runspace
    $backgroundRunspace = [runspacefactory]::CreateRunspace()
    $backgroundRunspace.ApartmentState = "STA"
    $backgroundRunspace.Open()
    
    # Share variables with runspace
    $backgroundRunspace.SessionStateProxy.SetVariable("logFile", $script:logFile)
    $backgroundRunspace.SessionStateProxy.SetVariable("SCRIPT_DIR", $SCRIPT_DIR)
    $backgroundRunspace.SessionStateProxy.SetVariable("JOB_MANIFEST_PATH", $JOB_MANIFEST_PATH)
    $backgroundRunspace.SessionStateProxy.SetVariable("SCRIPTS_FOLDER", $SCRIPTS_FOLDER)
    
    # Create PowerShell instance for background processing
    $backgroundPS = [powershell]::Create()
    $backgroundPS.Runspace = $backgroundRunspace
    
    # Background processing script block - COMPLETELY CLEANED
    $backgroundScript = {
        param($logFile, $SCRIPT_DIR, $JOB_MANIFEST_PATH, $SCRIPTS_FOLDER)
        
        function Write-LogMessage {
            param([string]$Level = "INFO", [string]$Message)
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            $logEntry = "[$timestamp] [BG-$Level] $Message"
            if ($logFile) {
                try { $logEntry | Out-File -FilePath $logFile -Append -Encoding UTF8 } catch {}
            }
        }
        
        Write-LogMessage "INFO" "Starting background processes..."
        
        # Phase 1: Initialization Script
        Write-LogMessage "INFO" "Phase 1: Running initialization script..."
        try {
            if (Test-Path "C:\Users\Public\initializationComplete.ps1") {
                Write-LogMessage "INFO" "Executing initialization script"
                $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"C:\Users\Public\initializationComplete.ps1`"" -Wait -PassThru -WindowStyle Hidden
                Write-LogMessage "INFO" "Initialization script completed with exit code: $($process.ExitCode)"
            } else {
                Write-LogMessage "WARN" "Initialization script not found"
            }
        } catch {
            Write-LogMessage "ERROR" "Initialization script failed: $($_.Exception.Message)"
        }
        
        # Phase 2: Process Drivers
        Write-LogMessage "INFO" "Phase 2: Processing drivers..."
        try {
            if (Test-Path $JOB_MANIFEST_PATH) {
                $content = Get-Content $JOB_MANIFEST_PATH -Raw -ErrorAction Stop
                $jobManifest = $content | ConvertFrom-Json -ErrorAction Stop
                
                if ($jobManifest -and $jobManifest.drivers -and $jobManifest.drivers.items) {
                    $drivers = @($jobManifest.drivers.items | Where-Object { $_.status -eq "pending" -and $_.requires_yunona })
                    $totalDrivers = $drivers.Count
                    Write-LogMessage "INFO" "Found $totalDrivers drivers to process"
                    
                    if ($totalDrivers -gt 0) {
                        for ($i = 0; $i -lt $totalDrivers; $i++) {
                            $driver = $drivers[$i]
                            Write-LogMessage "INFO" "Processing driver $($i+1)/$($totalDrivers): $($driver.name)"
                            
                            if ($driver.yunona_path) {
                                $silentCmdPath = Join-Path $driver.yunona_path "_silent.cmd"
                                if (Test-Path $silentCmdPath) {
                                    try {
                                        Write-LogMessage "INFO" "Executing: $silentCmdPath"
                                        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$silentCmdPath`"" -WorkingDirectory $driver.yunona_path -Wait -PassThru -WindowStyle Hidden
                                        Write-LogMessage "INFO" "Driver $($driver.name) completed with exit code: $($process.ExitCode)"
                                    } catch {
                                        Write-LogMessage "WARN" "Driver $($driver.name) execution failed: $($_.Exception.Message)"
                                    }
                                } else {
                                    Write-LogMessage "WARN" "Silent installer not found: $silentCmdPath"
                                }
                            } else {
                                Write-LogMessage "WARN" "Driver $($driver.name) has no yunona_path"
                            }
                        }
                    }
                } else {
                    Write-LogMessage "INFO" "No drivers section found in job manifest"
                }
            } else {
                Write-LogMessage "WARN" "Job manifest not found: $JOB_MANIFEST_PATH"
            }
        } catch {
            Write-LogMessage "ERROR" "Driver processing failed: $($_.Exception.Message)"
        }
        
		# Phase 3: Process Updates
		Write-LogMessage "INFO" "Phase 3: Processing updates..."
		try {
			if (Test-Path $JOB_MANIFEST_PATH) {
				$content = Get-Content $JOB_MANIFEST_PATH -Raw -ErrorAction Stop
				$jobManifest = $content | ConvertFrom-Json -ErrorAction Stop
				
				if ($jobManifest -and $jobManifest.updates -and $jobManifest.updates.items) {
					$updates = @($jobManifest.updates.items | Where-Object { $_.status -eq "pending" -and $_.requires_yunona })
					$totalUpdates = $updates.Count
					Write-LogMessage "INFO" "Found $totalUpdates updates to process"
					
					if ($totalUpdates -gt 0) {
						for ($i = 0; $i -lt $totalUpdates; $i++) {
							$update = $updates[$i]
							Write-LogMessage "INFO" "Processing update $($i+1)/$($totalUpdates): $($update.name)"
							
							if ($update.yunona_path) {
								$silentCmdPath = Join-Path $update.yunona_path "_silent.cmd"
								if (Test-Path $silentCmdPath) {
									try {
										Write-LogMessage "INFO" "Executing: $silentCmdPath"
										$process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$silentCmdPath`"" -WorkingDirectory $update.yunona_path -Wait -PassThru -WindowStyle Hidden
										Write-LogMessage "INFO" "Update $($update.name) completed with exit code: $($process.ExitCode)"
									} catch {
										Write-LogMessage "WARN" "Update $($update.name) execution failed: $($_.Exception.Message)"
									}
								} else {
									Write-LogMessage "WARN" "Silent installer not found: $silentCmdPath"
								}
							} else {
								Write-LogMessage "WARN" "Update $($update.name) has no yunona_path"
							}
						}
					}
				} else {
					Write-LogMessage "INFO" "No updates section found in job manifest"  
				}
			} else {
				Write-LogMessage "WARN" "Job manifest not found: $JOB_MANIFEST_PATH"
			}
		} catch {
			Write-LogMessage "ERROR" "Update processing failed: $($_.Exception.Message)"
		}
        
        # Phase 4: Process Scripts Folder
        Write-LogMessage "INFO" "Phase 4: Processing PowerShell scripts..."
        try {
            if (Test-Path $SCRIPTS_FOLDER) {
                $scriptFiles = @(Get-ChildItem -Path $SCRIPTS_FOLDER -Filter "*.ps1" -File | Sort-Object Name)
                $totalScripts = $scriptFiles.Count
                Write-LogMessage "INFO" "Found $totalScripts PowerShell scripts to execute"
                
                if ($totalScripts -gt 0) {
                    for ($i = 0; $i -lt $totalScripts; $i++) {
                        $scriptFile = $scriptFiles[$i]
                        Write-LogMessage "INFO" "Executing script $($i+1)/$($totalScripts): $($scriptFile.Name)"
                        
                        try {
                            $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($scriptFile.FullName)`"" -Wait -PassThru -WindowStyle Hidden
                            Write-LogMessage "INFO" "Script $($scriptFile.Name) completed with exit code: $($process.ExitCode)"
                        } catch {
                            Write-LogMessage "WARN" "Script $($scriptFile.Name) execution failed: $($_.Exception.Message)"
                        }                    
                    }
                } else {
                    Write-LogMessage "INFO" "No PowerShell scripts found in scripts folder"
                }
            } else {
                Write-LogMessage "INFO" "Scripts folder not found: $SCRIPTS_FOLDER"
            }
        } catch {
            Write-LogMessage "ERROR" "Scripts processing failed: $($_.Exception.Message)"
        }
        
        # Phase 5: Finalization
        Write-LogMessage "INFO" "Phase 5: Finalizing installation..."
        
        Write-LogMessage "INFO" "=== Background Processing Completed ==="
        
        # Signal completion
        try {
            $completionFlagPath = Join-Path $SCRIPT_DIR "yunona_completion.flag"
            "COMPLETED $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $completionFlagPath -Encoding ASCII
            Write-LogMessage "INFO" "Completion flag file created successfully"
        } catch {
            Write-LogMessage "ERROR" "Failed to create completion flag: $($_.Exception.Message)"
        }
    }
    
    # Add script block and parameters
    [void]$backgroundPS.AddScript($backgroundScript)
    [void]$backgroundPS.AddParameter("logFile", $script:logFile)
    [void]$backgroundPS.AddParameter("SCRIPT_DIR", $SCRIPT_DIR)
    [void]$backgroundPS.AddParameter("JOB_MANIFEST_PATH", $JOB_MANIFEST_PATH)
    [void]$backgroundPS.AddParameter("SCRIPTS_FOLDER", $SCRIPTS_FOLDER)
    
    # Start asynchronous execution
    $asyncResult = $backgroundPS.BeginInvoke()
    
    Write-LogMessage "INFO" "Background processing started asynchronously"
}

function Get-ImageFiles {
    Write-LogMessage "INFO" "Scanning for image files in: $IMAGES_FOLDER"
    
    if (-not (Test-Path $IMAGES_FOLDER)) {
        Write-LogMessage "WARN" "Images folder not found: $IMAGES_FOLDER"
        return @()
    }
    
    $imageExtensions = @("*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif")
    $imageFiles = @()
    
    foreach ($extension in $imageExtensions) {
        $files = Get-ChildItem -Path $IMAGES_FOLDER -Filter $extension -File -ErrorAction SilentlyContinue
        $imageFiles += $files
    }
    
    $imageFiles = $imageFiles | Sort-Object Name
    Write-LogMessage "INFO" "Found $($imageFiles.Count) image files"
    
    return $imageFiles
}

function Show-NextImage {
    if ($script:images.Count -eq 0) { 
        Write-LogMessage "WARN" "No images available for slideshow"
        return 
    }
    
    try {
        $imagePath = $script:images[$script:currentImageIndex].FullName
        
        if (-not (Test-Path $imagePath)) {
            Write-LogMessage "ERROR" "Image file not found: $imagePath"
            $script:currentImageIndex = ($script:currentImageIndex + 1) % $script:images.Count
            return
        }
        
        # Load bitmap
        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmap.BeginInit()
        $bitmap.UriSource = New-Object System.Uri($imagePath)
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.EndInit()
        $bitmap.Freeze()
        
        $script:window.Dispatcher.Invoke([System.Action]{
            try {
                $mainImage = $script:window.FindName("MainImage")
                
                if (-not $mainImage) {
                    Write-LogMessage "ERROR" "MainImage not found in window"
                    return
                }
                
                # Choose animation method
                if ($USE_ANIMATIONS) {
                    switch ($ANIMATION_TYPE) {
                        "fade" { Start-StoryboardFade $mainImage $bitmap }
                        default { Set-ImageDirectly $mainImage $bitmap }
                    }
                } else {
                    Set-ImageDirectly $mainImage $bitmap
                }
                
            }
            catch {
                Write-LogMessage "ERROR" "Error in UI thread image display: $($_.Exception.Message)"
            }
        })
        
        # Move to next image
        $script:currentImageIndex = ($script:currentImageIndex + 1) % $script:images.Count
        
    }
    catch {
        Write-LogMessage "ERROR" "Failed to load image: $($_.Exception.Message)"
        $script:currentImageIndex = ($script:currentImageIndex + 1) % $script:images.Count
    }
}

function Set-ImageDirectly {
    param($imageElement, $bitmap)
    try {
        # Stop all animations
        $imageElement.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
        $imageElement.Source = $bitmap
        $imageElement.Opacity = 1.0
    }
    catch {
        Write-LogMessage "ERROR" "Error in direct image set: $($_.Exception.Message)"
    }
}

function Start-StoryboardFade {
    param($imageElement, $bitmap)
    try {
        $script:pendingBitmap = $bitmap
        
        # Create and start fade-out storyboard
        $storyboard = New-Object System.Windows.Media.Animation.Storyboard
        
        $fadeOutAnimation = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fadeOutAnimation.From = 1.0
        $fadeOutAnimation.To = 0.1
        $fadeOutAnimation.Duration = [TimeSpan]::FromMilliseconds([int]($ANIMATION_DURATION / 2))
        $fadeOutAnimation.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
        
        [System.Windows.Media.Animation.Storyboard]::SetTarget($fadeOutAnimation, $imageElement)
        [System.Windows.Media.Animation.Storyboard]::SetTargetProperty($fadeOutAnimation, [System.Windows.PropertyPath]::new("Opacity"))
        
        $storyboard.Children.Add($fadeOutAnimation)
        
        $storyboard.Add_Completed({
            try {
                $img = $script:window.FindName("MainImage")
                if ($img -and $script:pendingBitmap) {
                    $img.Source = $script:pendingBitmap
                    
                    # Fade in
                    $fadeInStoryboard = New-Object System.Windows.Media.Animation.Storyboard
                    $fadeInAnimation = New-Object System.Windows.Media.Animation.DoubleAnimation
                    $fadeInAnimation.From = 0.1
                    $fadeInAnimation.To = 1.0
                    $fadeInAnimation.Duration = [TimeSpan]::FromMilliseconds([int]($ANIMATION_DURATION / 2))
                    $fadeInAnimation.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
                    
                    [System.Windows.Media.Animation.Storyboard]::SetTarget($fadeInAnimation, $img)
                    [System.Windows.Media.Animation.Storyboard]::SetTargetProperty($fadeInAnimation, [System.Windows.PropertyPath]::new("Opacity"))
                    
                    $fadeInStoryboard.Children.Add($fadeInAnimation)
                    $fadeInStoryboard.Add_Completed({
                        $script:pendingBitmap = $null
                    })
                    
                    $fadeInStoryboard.Begin()
                }
            }
            catch {
                Write-LogMessage "ERROR" "Storyboard fade completion error: $($_.Exception.Message)"
                $script:pendingBitmap = $null
            }
        })
        
        $storyboard.Begin()
    }
    catch {
        Write-LogMessage "ERROR" "Error starting storyboard fade: $($_.Exception.Message)"
        Set-ImageDirectly $imageElement $bitmap
        $script:pendingBitmap = $null
    }
}

function Start-SlideShow {
    if ($script:images.Count -eq 0) {
        Write-LogMessage "WARN" "No images found for slideshow"
        return
    }
    
    Write-LogMessage "INFO" "Starting slideshow with $($script:images.Count) images"
    
    # Load first image immediately
    try {
        $imagePath = $script:images[$script:currentImageIndex].FullName
        
        if (Test-Path $imagePath) {
            $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
            $bitmap.BeginInit()
            $bitmap.UriSource = New-Object System.Uri($imagePath)
            $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bitmap.EndInit()
            $bitmap.Freeze()
            
            $script:window.Dispatcher.Invoke([System.Action]{
                $mainImage = $script:window.FindName("MainImage")
                if ($mainImage) {
                    Set-ImageDirectly $mainImage $bitmap
                }
            })
            
            $script:currentImageIndex = ($script:currentImageIndex + 1) % $script:images.Count
        }
    }
    catch {
        Write-LogMessage "ERROR" "Failed to load first image: $($_.Exception.Message)"
    }
    
    # Create timer for slideshow
    $script:slideTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:slideTimer.Interval = [TimeSpan]::FromMilliseconds($SLIDE_INTERVAL)
    $script:slideTimer.Add_Tick({ Show-NextImage })
    $script:slideTimer.Start()
}

function Create-MainWindow {
    Write-LogMessage "INFO" "Creating main window ($WINDOW_WIDTH x $WINDOW_HEIGHT)"
    
    # XAML with Status Label between Image and Progress Bar
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Yunona - System Preparation" 
        Width="$WINDOW_WIDTH" 
        Height="$WINDOW_HEIGHT"
        WindowStartupLocation="CenterScreen"
        Background="Black"
        ResizeMode="NoResize"
        Topmost="True"
        WindowStyle="None">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="$IMAGE_HEIGHT"/>
            <RowDefinition Height="$STATUS_HEIGHT"/>
            <RowDefinition Height="$PROGRESS_HEIGHT"/>
        </Grid.RowDefinitions>
        
        <!-- Image Display Area -->
        <Grid Name="ImageHost" Grid.Row="0" Background="Black" ClipToBounds="True">
          <Image Name="MainImage"
                 Width="$IMAGE_WIDTH"
                 Height="$IMAGE_HEIGHT"
                 Stretch="UniformToFill"
                 HorizontalAlignment="Center"
                 VerticalAlignment="Center"
                 Opacity="1.0"
                 CacheMode="BitmapCache"
                 RenderOptions.BitmapScalingMode="HighQuality"/>
        </Grid>
        
        <!-- Status Label -->
        <Border Name="StatusContainer" Grid.Row="1" Background="#1a1a1a" Padding="20,0">
            <TextBlock Name="StatusLabel" 
                       Text="Preparing your Industrial PC for operation - Please wait..."
                       Foreground="White"
                       FontSize="16"
                       FontWeight="Normal"
                       HorizontalAlignment="Center"
                       VerticalAlignment="Center"
                       TextAlignment="Center"/>
        </Border>
        
        <!-- Progress Area -->
        <Border Name="ProgressContainer" Grid.Row="2" Background="#1e1e1e" Padding="20,25">
            <Grid>
                <!-- Progress Bar Only (no text) -->
                <ProgressBar Name="ProgressBar" 
                           Height="25" 
                           Minimum="0" 
                           Maximum="100" 
                           Value="0"
                           Background="#333333"
                           Foreground="#4CAF50"
                           BorderThickness="0"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    try {
        $reader = New-Object System.Xml.XmlNodeReader $xaml
        $script:window = [Windows.Markup.XamlReader]::Load($reader)
        
        # Add hotkey to close
        $script:window.Add_KeyDown({
            param($sender, $e)
            if ($e.Key -eq [System.Windows.Input.Key]::C -and 
                $e.KeyboardDevice.Modifiers -eq ([System.Windows.Input.ModifierKeys]::Control -bor [System.Windows.Input.ModifierKeys]::Alt)) {
                Write-LogMessage "INFO" "Close hotkey pressed (CTRL+ALT+C)"
                $script:allowClose = $true
                $script:window.Close()
            }
        })
        
        # Handle closing
        $script:window.Add_Closing({
            param($sender, $e)
            if (-not $script:allowClose) {
                $e.Cancel = $true
            } else {
                Write-LogMessage "INFO" "Window closing - cleaning up"
                if ($script:slideTimer) { $script:slideTimer.Stop() }
            }
        })
        
        Write-LogMessage "INFO" "Main window created successfully"
        return $script:window
    }
    catch {
        Write-LogMessage "ERROR" "Failed to create main window: $($_.Exception.Message)"
        return $null
    }
}

# Main execution
function Start-Yunona {
    # Initialize logging
    Initialize-LogFile
    
    Write-LogMessage "INFO" "=== Starting Yunona System ==="
    Write-LogMessage "INFO" "Hidden Terminal Version: UI First, Background Processing with Status Label"
    
    # Get image files
    $script:images = Get-ImageFiles
    
    # Create and show window FIRST
    $script:window = Create-MainWindow
    
    if ($script:window) {
        # Start slideshow immediately
        Start-SlideShow
        
        # Start continuous progress bar animation
        Write-LogMessage "INFO" "Starting continuous progress bar animation"
        
        $script:window.Dispatcher.Invoke([System.Action]{
            try {
                $progressBar = $script:window.FindName("ProgressBar")
                if ($progressBar) {
                    
                    # Smooth Left-to-Right Continuous Animation
                    $storyboard = New-Object System.Windows.Media.Animation.Storyboard
                    $storyboard.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                    $animation = New-Object System.Windows.Media.Animation.DoubleAnimation
                    $animation.From = 0
                    $animation.To = 100
                    $animation.Duration = [TimeSpan]::FromSeconds(2)
                    $animation.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                    $animation.AutoReverse = $false  # Always left to right, restart
                    $animation.EasingFunction = New-Object System.Windows.Media.Animation.CubicEase
                    
                    [System.Windows.Media.Animation.Storyboard]::SetTarget($animation, $progressBar)
                    [System.Windows.Media.Animation.Storyboard]::SetTargetProperty($animation, [System.Windows.PropertyPath]::new("Value"))
                    
                    $storyboard.Children.Add($animation)
                    $storyboard.Begin()
                    
                    Write-LogMessage "INFO" "Continuous progress bar animation started"
                }
            }
            catch {
                Write-LogMessage "ERROR" "Failed to start progress bar animation: $($_.Exception.Message)"
            }
        })
        
        # Start background completion checker
        $completionChecker = New-Object System.Windows.Threading.DispatcherTimer
        $completionChecker.Interval = [TimeSpan]::FromMilliseconds(1000)  # Check every second
        $completionChecker.Add_Tick({ Update-ProgressDisplay })
        $completionChecker.Start()
        Write-LogMessage "INFO" "Background completion checker started"
        
        # Start background processing after UI is ready
        $initTimer = New-Object System.Windows.Threading.DispatcherTimer
        $initTimer.Interval = [TimeSpan]::FromMilliseconds(500)
        $initTimer.Add_Tick({
            Start-BackgroundProcessing
            $initTimer.Stop()
        })
        $initTimer.Start()
        
        Write-LogMessage "INFO" "Displaying main window - background processing will start in 0.5 seconds"
        Write-LogMessage "INFO" "Use CTRL+ALT+C to close the application"
        $script:window.ShowDialog()
        
        Write-LogMessage "INFO" "=== Yunona System Ended ==="
    } else {
        Write-LogMessage "ERROR" "Failed to create main window"
    }
}

# Start the application
Start-Yunona