# Synology Drive Client Deployment Script
# Fill $INSTALLER_PATH with path to the installer EXE

$INSTALLER_PATH = './sdc-4.0.1-17885-x64.msi'
$CONFIG_PATH = './dewan_config.json'

function install {
    param($INSTALLER_PATH, $NEW_PATH, $LOG_PATH)
    Write-Host "Attempting to install the Synology Drive Client..." -ForegroundColor Yellow
    # Installation code to run in spinner function
    $install = {
        param($installer, $config_path, $log_path)
        # Write msiexec.log, quiet mode, CONFIGPATH is the json file; make sure it is run as admin; pass through exit code
        return (start-process "msiexec.exe" -arg "/i `"$($installer)`" /l*v $($log_path) /qn CONFIGPATH=`"$($config_path)`" " -Wait -PassThru -verb RunAs).ExitCode 
    }

    # Run installation inside of spinner
    $result = run_with_spinner $install $INSTALLER_PATH, $NEW_PATH, $LOG_PATH "Installing Synology Drive Client..."
    
    if (-not $result -eq 0){
        Write-Error "Error installing Synology Drive Client!"
        exit 1
    }
    Write-Host "Successfully installed Synology Drive Client!" -ForegroundColor Green
}

function check_and_uninstall {
    # Source - https://stackoverflow.com/a
    # Posted by nickdnk, modified by community. See post 'Timeline' for change history
    # Retrieved 2025-11-19, License - CC BY-SA 3.0

    Write-Host "Checking if Synology Drive Client is installed..." -ForegroundColor Yellow

    # Find uninstaller file for Synology Drive if they exist
    $uninstall32 = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_ -match "Synology Drive" }
    $uninstall64 = gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_ -match "Synology Drive" }

    if ($uninstall32){
        $uninstall_obj = $uninstall32
    }
    elseif ($uninstall64){
        $uninstall_obj = $uninstall64
    }
    else{
        Write-Host "Synology Drive Client is not installed, continuing!" -ForegroundColor Green
        return 0
    }

    Write-Host "Synology Drive Client Found! Attempting to Uninstall...`n" -ForegroundColor Yellow
    
    # Modify the msiexec command and run it
    $uninstall = {
        param($uninstall_obj)
        $uninstall_str = $uninstall_obj.UninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X",""
        $uninstall_str = $uninstall_str.Trim()
        return (start-process "msiexec.exe" -arg "/X $uninstall_str /qb" -Wait -PassThru).ExitCode 
    }
    
    $result = run_with_spinner $uninstall $uninstall_obj "Attempting to uninstall Synology Drive Client"

    if (-not $result -eq 0){
        Write-Error "Error uninstalling Synology Drive Client! Uninstall manually and retry!"
        Exit 1
    }

    Write-Host "Successfully uninstalled the Synology Drive Client!" -ForegroundColor Green
}

function run_with_spinner {
    # Retrieved from https://gist.github.com/yoav-lavi/1253321d968db7f52d1a77ac48e3ff96 | 11/19/2025
    # Modified by Austin Pauley, 2025
    param([scriptblock]$function, $argument, [string]$Label)

    $job = Start-Job -ScriptBlock $function -ArgumentList $argument

    $symbols = @("|", "/", "--", "\")
    $i = 0;
    while ($job.State -eq "Running") {
        $symbol =  $symbols[$i]
        Write-Host -NoNewLine "`r$symbol $Label" -ForegroundColor Green
        Start-Sleep -Milliseconds 100
        $i++
        if ($i -eq $symbols.Count){
            $i = 0;
        }   
    }
    Write-Host -NoNewLine "`r"
    Write-Host

    return $job | Receive-Job
}


Write-Host "Synology Drive Client Mass Deployment Script" -ForegroundColor Cyan
Write-Host "Austin Pauley, Florida State University, 2025" -ForegroundColor Cyan
Write-Host "=============================================`n" -ForegroundColor Cyan
Write-Host "Adding computer name to backup destination path" -ForegroundColor Yellow

# Load the config file and parse json
$config_file = Get-Content $CONFIG_PATH -raw | ConvertFrom-Json
# Append the computer name to the base backup directory
$existing_path = $config_file.connections.backup_task.backup_destination.remote_path
$new_path = $existing_path + $env:COMPUTERNAME + '/'
$config_file.connections.backup_task.backup_destination.remote_path = $new_path # Set key to new path
Write-Host "New Remote Backup Path $($config_file.connections.backup_task.backup_destination.remote_path)" # Print new path
# Write json file to disk
$config_file | ConvertTo-Json -depth 100 | set-content ".\custom_config.json"

# Absolute Paths
$abs_path = Resolve-Path $INSTALLER_PATH
$abs_config_path = Resolve-Path ".\custom_config.json"
$log_path = (Resolve-Path ".").Path + "\msiexec.log"

# Check if Installer file exists
if ( -Not [System.IO.File]::Exists($abs_path) ) {
    Write-Error "Cannot find the Synology Drive Client Installer in [$($abs_path)]! Please check the file exists and try running the script again."
    exit 1
}

# Check if Client is Already installed, uninstall if so
check_and_uninstall

# Install Client
install $abs_path $abs_config_path $log_path

# Remove modified backup file
Remove-Item $abs_config_path -Force