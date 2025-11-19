# Synology Drive Client Deployment Script
# Fill $INSTALLER_PATH with path to the installer EXE

$INSTALLER_PATH = 'PATH/TO/INSTALLER.EXE'

Write-Host "Synology Drive Client Mass Deployment Script" -ForegroundColor Cyan
Write-Host "Austin Pauley, Florida State University, 2025" -ForegroundColor Cyan
Write-Host "=============================================`n" -ForegroundColor Cyan
Write-Host "Adding computer name to backup destination path" -ForegroundColor Yellow

$config_file = Get-Content ".\config.json" -raw | ConvertFrom-Json
$existing_path = $config_file.connections.backup_task.backup_destination.remote_path
$new_path = $existing_path + $env:COMPUTERNAME + '/'
$config_file.connections.backup_task.backup_destination.remote_path = $new_path # Set key to new path
Write-Host "New Remote Backup Path $($config_file.connections.backup_task.backup_destination.remote_path)" # Print new path

$config_file | ConvertTo-Json -depth 100 | set-content ".\custom_config.json"

# Run Installer
Write-Host "Running Synology Drive Client Installer"

if ( -Not [System.IO.File]::Exists($INSTALLER_PATH) ) {
    # Write-Error "Cannot find the Synology Drive Client Installer in [$($INSTALLER_PATH)]! Please check the file exists and try running the script again."
    # exit 1
}

# Check if Client is Already installed, uninstall if so
check_and_uninstall

function check_and_uninstall {
    # Source - https://stackoverflow.com/a
    # Posted by nickdnk, modified by community. See post 'Timeline' for change history
    # Retrieved 2025-11-19, License - CC BY-SA 3.0

    Write-Host "Checking if Synology Drive Client is installed..." -ForegroundColor Yellow

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
    return 0
}

function run_with_spinner {
    param([scriptblock]$function, $argument, [string]$Label)

    $job = Start-Job -ScriptBlock $function -ArgumentList $argument

    $symbols = @("⣾⣿", "⣽⣿", "⣻⣿", "⢿⣿", "⡿⣿", "⣟⣿", "⣯⣿", "⣷⣿",
                 "⣿⣾", "⣿⣽", "⣿⣻", "⣿⢿", "⣿⡿", "⣿⣟", "⣿⣯", "⣿⣷")
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