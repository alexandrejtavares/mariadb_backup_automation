# Verify the environment variables
If ([string]::IsNullOrEmpty($Env:DB_PATH) -or [string]::IsNullOrEmpty($Env:DB_USER) -or [string]::IsNullOrEmpty($Env:DB_PWD) -or [string]::IsNullOrEmpty($Env:BACKUP_PATH)){ 
    Throw "Environment variables 'DB_PATH', 'DB_USER', 'DB_PWD', 'BACKUP_PATH' are not defined as expected. Execute the script 'install_scripts.ps1: DB_PATH = $Env:DB_PATH, DB_USER = $Env:DB_USER, DB_PWD = $Env:DB_PWD, BACKUP_PATH = $Env:BACKUP_PATH."
}

# Check if the path "last_backup" exists and create it if it doesn't.
If (-Not (Test-Path "$Env:BACKUP_PATH\last_backup")){ 
    New-Item -Path "$Env:BACKUP_PATH\last_backup\full" -ItemType Directory
} else {
    #del "$Env:BACKUP_PATH\last_backup\*"
    Get-ChildItem -Path "$Env:BACKUP_PATH\last_backup\full\*" -Recurse | Remove-Item -Recurse
}

# Move all files to last_backup directory.
If (Test-Path "$Env:BACKUP_PATH\full"){ 
    Get-ChildItem -Path "$Env:BACKUP_PATH\full\*" -Recurse | Move-Item -Destination "$Env:BACKUP_PATH\last_backup\full\"    
}

$program = "& " + "'${Env:DB_PATH}" + "\bin\mariabackup' --backup --target-dir=$Env:BACKUP_PATH\full --user=$Env:DB_USER --password=$Env:DB_PWD"

try{
    # Full Backup
    Invoke-Expression "$program"
    Write-Host "Full backup completed successfully."
} catch {
    Write-Host "An error occurs when executing MariaDB Full Backup."
} 

