#### VARIABLES ####
$Logfile = "$PSScriptRoot\mariadb_incrementalbackup.log"

#### FUNCTIONS ####
function Test-Variable {
    param (
        [String]$VariableName, 
        [String]$VariableValue
    )

    if ([string]::IsNullOrEmpty($VariableValue)) {
        $MessageText = "Environment variable $VariableName is not defined as expected. `
        Execute the script 'install_scripts.ps1' to set the environment variables correctly."
        Write-Error $MessageText
        WriteLog($MessageText)
    }   
}
function WriteLog {
    Param ([string]$LogString)
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
}

# Verify the environment variables
WriteLog("Verifying if expected Environment variables are defined...")
Test-Variable('DB_PATH', $Env:DB_PATH)
Test-Variable('DB_USER', $Env:DB_USER)
Test-Variable('DB_PWD', $Env:DB_PWD)
Test-Variable('BACKUP_PATH', $Env:BACKUP_PATH)

# Checks if a backup full exists and creates one if not
WriteLog("Verifying if the backup full was executed previously...")
If (-Not (Test-Path -Path "$Env:BACKUP_PATH\*")) {
    $MessageText = "Backup full don't exists. Run backup full before incremental."
    Write-Error $MessageText
    WriteLog($MessageText)
}

# Check if the path "last_backup" exists and create it if it doesn't.
WriteLog("Verifying if the 'last_backup' folder exists and create it if it doesn't...")
If (-Not (Test-Path "$Env:BACKUP_PATH\last_backup\incremental")) {     
    try{
        New-Item -Path "$Env:BACKUP_PATH\last_backup\incremental" -ItemType Directory
        WriteLog("'last_backup' folder created successfully")
    } catch {
        $MessageText = "Error creating 'last_backup' folder."
        Write-Error $MessageText
        WriteLog($MessageText)
    } 
    
}
else {
    WriteLog("Deleting previous incremental backup...")
    try{
        Get-ChildItem -Path "$Env:BACKUP_PATH\last_backup\incremental\*" -Recurse | Remove-Item -Recurse
        WriteLog("Previous incremental backup deleted successfully...")
    } catch {
        $MessageText = "Error deleting previous incremental backup."
        Write-Error $MessageText
        WriteLog($MessageText)
    }   
}

# Move all files to last_backup\incremental directory.
WriteLog("Moving previous incremental backup to folder 'last_backup\incremental'...")
try{
    Get-ChildItem -Path "$Env:BACKUP_PATH\incremental\*" -Recurse | Move-Item -Destination "$Env:BACKUP_PATH\last_backup\incremental\"
    WriteLog("Previous incremental backup moved successfully.")
} catch {
    $MessageText = "Error moving previous incremental backup to folder 'last_backup\incremental'."
    Write-Error($MessageText)
    WriteLog($MessageText)
}

# Incremental backup command
$program = "&" + "'${Env:DB_PATH}" + "\bin\mariabackup' --backup --target-dir=$Env:BACKUP_PATH\incremental --incremental-basedir=$Env:BACKUP_PATH\full --user=$Env:DB_USER --password=$Env:DB_PWD"

try {
    # Incremental Backup
    WriteLog("Running MariaDB incremental backup...")
    Invoke-Expression -Command "$program"
    $MessageText = "MariaDB incremental backup generated successfully."
    Write-Output $MessageText
    WriteLog($MessageText)
}
catch {
    $MessageText = "An error occurs when executing MariaDB Incremental Backup."
    Write-Error $MessageText
    WriteLog($MessageText)
} 