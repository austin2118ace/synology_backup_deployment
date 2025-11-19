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

