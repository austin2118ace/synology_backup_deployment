$config_file = Get-Content ".\config.json" -raw | ConvertFrom-Json
$existing_path = $config_file.connections.backup_task.backup_destination.remote_path
$new_path = $existing_path + $env:COMPUTERNAME + '/'
$config_file.connections.backup_task.backup_destination.remote_path = $new_path

Write-Host $config_file.connections.backup_task.backup_destination.remote_path

$config_file | ConvertTo-Json -depth 100 | set-content ".\custom_config.json"

