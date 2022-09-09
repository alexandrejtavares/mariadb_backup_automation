#### CONFIG FILE ####
. $PSScriptRoot\config.ps1

#### VARIABLES ####
$Logfile = $IncrementalBackupLogFile

#### FUNCTIONS ####
function Test-Variable([String]$VariableName, [String]$VariableValue) {
    if (-Not $VariableValue) {
        $MessageText = "Environment variable $VariableName is not defined as expected. Execute the script 'install_scripts.ps1' to set the environment variables correctly."
        WriteLog $MessageText $true
    }
}
function WriteLog([string]$LogString, [bool]$PrintLog) {
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
    if ($PrintLog) {
        Write-Output($LogString)
    }
}

$FormatedDate = (Get-Date).toString("yyyyMMdd_HHmm")
$FormatedDateWithoutTime = (Get-Date).toString("yyyyMMdd")

# Verify the environment variables
WriteLog "#################################################################################" $false
WriteLog "Verifying if expected Environment variables are defined..." $true
Test-Variable 'DB_PATH' $Env:DB_PATH
Test-Variable 'DB_USER' $Env:DB_USER
Test-Variable 'DB_PWD' $Env:DB_PWD
Test-Variable 'BACKUP_PATH' $Env:BACKUP_PATH
WriteLog "Environment variables found sucessfuly." $true


# Checks if a backup full exists
WriteLog "Verifying if the backup full was executed previously in folder full_$FormatedDateWithoutTime..." $true
If (-Not (Test-Path -Path "$Env:BACKUP_PATH\full_$FormatedDateWithoutTime\*")) {
    $MessageText = "Backup full doesn't exists. Run backup full before incremental."
    WriteLog $MessageText $true
    Throw $MessageText
}
WriteLog "Backup full found as expected." $true

# Check if the path "last_backup" exists and create it if it doesn't.
WriteLog "Verifying if the incremental_$FormatedDate folder exists and create it if doesn't..." $true
If (-Not (Test-Path "$Env:BACKUP_PATH\incremental_$FormatedDate")) {
    try {
        New-Item -Path "$Env:BACKUP_PATH\incremental_$FormatedDate" -ItemType Directory
        WriteLog "Folder incremental_$FormatedDate created successfully." $true
    }
    catch {
        $MessageText = "Error creating incremental_$FormatedDate folder."
        WriteLog $MessageText $true
    } 
    
} else {
    WriteLog "Previous incremental backup found. Deleting previous incremental backup..." $true
    try {
        Get-ChildItem -Path "$Env:BACKUP_PATH\incremental_$FormatedDate\*" -Recurse | Remove-Item -Recurse
        WriteLog "Previous incremental backup deleted successfully." $true
    }
    catch {
        $MessageText = "Error deleting previous incremental backup."
        WriteLog $MessageText $true
    }   
}

# Incremental backup command
$program = "&" + "'${Env:DB_PATH}" + "\bin\mariabackup' --backup --target-dir=$Env:BACKUP_PATH\incremental_$FormatedDate --incremental-basedir=$Env:BACKUP_PATH\full_$FormatedDateWithoutTime --user=$Env:DB_USER --password=$Env:DB_PWD"

try {
    # Incremental Backup
    WriteLog "Running MariaDB incremental backup..." $true
    Invoke-Expression -Command "$program"
    WriteLog "MariaDB incremental backup generated successfully." $true
}
catch {
    WriteLog "An error occurs when executing MariaDB Incremental Backup." $true
}