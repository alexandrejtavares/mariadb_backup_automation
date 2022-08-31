Param(
    [Parameter(Mandatory, HelpMessage = "Enter the MariaDB path")] [string]$db_path,
    [Parameter(Mandatory, HelpMessage = "Provide an MariaDB user with backup authority")] [string]$db_user,
    [Parameter(Mandatory, HelpMessage = "Enter the user password")] [string]$db_pwd,
    [Parameter(Mandatory, HelpMessage = "Enter the path to save the MariaDB backup files")] [string]$backup_path,
    [Parameter(Mandatory, HelpMessage = "Provide an user with `Log on as a batch job` security policy")] [string]$batch_user,
    [Parameter(Mandatory, HelpMessage = "Enter the batch user password")] [string]$batch_user_pwd
)

# Validate parameters
If ([string]::IsNullOrEmpty($db_path) -or [string]::IsNullOrEmpty($db_user) -or [string]::IsNullOrEmpty($db_pwd) -or [string]::IsNullOrEmpty($backup_path) -or [string]::IsNullOrEmpty($batch_user)){ 
    Throw "One or more parameters are invalid. Please, execute the script again and fill all parameters."
}

# Validate paths
If (-Not (Test-Path $backup_path)){ 
    Throw "Path $backup_path is invalid or does not exist. Plase fill a valid path."
}
If (-Not (Test-Path $db_path)){ 
    Throw "Path $db_path is invalid or does not exist. Plase fill a valid path."
}

# Set environment variables
[System.Environment]::SetEnvironmentVariable('DB_PATH',$db_path, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('DB_USER',$db_user, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('DB_PWD',$db_pwd, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('BACKUP_PATH',$backup_path, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('BATCH_USER',$batch_user, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('BATCH_USER_PWD',$batch_user_pwd, [System.EnvironmentVariableTarget]::Machine)

# Create full backup task in Task Scheduler
$taskname = "MariaDB - Full Backup"
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NonInteractive -NoLogo -NoProfile -File $PSScriptRoot\mariadb_fullbackup.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 1am
$task = New-ScheduledTask -Action $action -Trigger $trigger -Description 'Task to run MariaDB full backup.'

$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskname }

if($taskExists) {
   Set-ScheduledTask -TaskName $taskname -User $batch_user -Password $batch_user_pwd -Action $action -Trigger $trigger
} else {
   Register-ScheduledTask -TaskName $taskname -User $batch_user -Password $batch_user_pwd -InputObject $task
}

# Create incremental backup task in Task Scheduler
$taskname = "MariaDB - Incremental Backup"
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NonInteractive -NoLogo -NoProfile -File $PSScriptRoot\mariadb_incrementalbackup.ps1"
$trigger = New-ScheduledTaskTrigger `
    -Once -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Hours 1) # Repeat every hour
$task = New-ScheduledTask -Action $action -Trigger $trigger -Description 'Task to run MariaDB incremental backup.'

$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskname }

if($taskExists) {
    Set-ScheduledTask -TaskName $taskname -User $batch_user -Password $batch_user_pwd -Action $action -Trigger $trigger
} else {
    Register-ScheduledTask -TaskName $taskname -User $batch_user -Password $batch_user_pwd -InputObject $task
}


Write-Host "Configurations finished successfully."
