#### VARIABLES ####
$Logfile = "$PSScriptRoot\mariadb_fullbackup.log"

#### FUNCTIONS ####
function WriteLog {
    Param ([string]$LogString)
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
}
function Test-Variable([String]$VariableName, [String]$VariableValue){
    if (-Not $VariableValue){
        $MessageText = "Environment variable $VariableName is not defined as expected. Execute the script 'install_scripts.ps1' to set the environment variables correctly."
        Write-Error($MessageText)
        WriteLog($MessageText)
    }   
}

# Verify the environment variables
WriteLog("#################################################################################")
WriteLog("Verifying if expected Environment variables are defined...")
Test-Variable 'DB_PATH' "$Env:DB_PATH"
Test-Variable 'DB_USER' "$Env:DB_USER"
Test-Variable 'DB_PWD' "$Env:DB_PWD"
Test-Variable 'BACKUP_PATH' "$Env:BACKUP_PATH"

# Check if the path "last_backup" exists and create it if it doesn't.
WriteLog("Checking if 'last_backup\full' folder exists... If it exists, delete its files, otherwise create this one.")
If (-Not (Test-Path "$Env:BACKUP_PATH\last_backup\full")){ 
    New-Item -Path "$Env:BACKUP_PATH\last_backup\full" -ItemType Directory
    WriteLog("Folder 'last_backup\full' created successfully.")
} else {
    WriteLog("Deleting previous full backup...")
    Get-ChildItem -Path "$Env:BACKUP_PATH\last_backup\full\*" -Recurse | Remove-Item -Recurse
    WriteLog("Previous full backup deleted successfully.")
}

# Move all files to last_backup directory.
WriteLog("Moving previous full backup to folder 'last_backup\incremental'...")
If (Test-Path "$Env:BACKUP_PATH\full"){
    Get-ChildItem -Path "$Env:BACKUP_PATH\full\*" -Recurse | Move-Item -Destination "$Env:BACKUP_PATH\last_backup\full\"
    WriteLog("Previous full backup moved successfully.")
}

# Full backup command
$program = "& " + "'${Env:DB_PATH}" + "\bin\mariabackup' --backup --target-dir=$Env:BACKUP_PATH\full --user=$Env:DB_USER --password=$Env:DB_PWD"

try{
    # Full Backup
    WriteLog("Running MariaDB full backup...")
    Invoke-Expression "$program"
    $MessageText = "MariaDB full backup generated successfully."
    Write-Output $MessageText
    WriteLog($MessageText)
} catch {
    $MessageText = "An error occurs when executing MariaDB full backup."
    Write-Error $MessageText
    WriteLog($MessageText)
} 

