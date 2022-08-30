# Verify the environment variables
If ([string]::IsNullOrEmpty($Env:DB_PATH) -or [string]::IsNullOrEmpty($Env:DB_USER) -or [string]::IsNullOrEmpty($Env:DB_PWD) -or [string]::IsNullOrEmpty($Env:BACKUP_PATH)){ 
    Throw "Environment variables 'DB_PATH', 'DB_USER', 'DB_PWD', 'BACKUP_PATH' are not defined as expected. Execute the script 'install_scripts.ps1.'"
}

# Checks if a full backup exists and creates one if not
If (-Not (Test-Path -Path "$Env:BACKUP_PATH\*")){
    Throw "Backup full don't exists. Run backup full before incremental."}

# Check if the path "last_backup" exists and create it if it doesn't.
If (-Not (Test-Path "$Env:BACKUP_PATH\last_backup\incremental")){ 
    New-Item -Path "$Env:BACKUP_PATH\last_backup\incremental" -ItemType Directory
} else {
    Get-ChildItem -Path "$Env:BACKUP_PATH\last_backup\incremental\*" -Recurse | Remove-Item -Recurse
}

# Move all files to last_backup\incremental directory.
Get-ChildItem -Path "$Env:BACKUP_PATH\incremental\*" -Recurse | Move-Item -Destination "$Env:BACKUP_PATH\last_backup\incremental\"

$program = "&" + "'${Env:DB_PATH}" + "\bin\mariabackup' --backup --target-dir=$Env:BACKUP_PATH\incremental --incremental-basedir=$Env:BACKUP_PATH\full --user=$Env:DB_USER --password=$Env:DB_PWD"

try{
    # Incremental Backup
    Invoke-Expression -Command "$program"
    Write-Host "Incremental backup completed successfully."
} catch {
    Write-Host "An error occurs when executing MariaDB Incremental Backup."
} 