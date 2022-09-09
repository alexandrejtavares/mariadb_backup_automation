#### CONFIG FILE ####
. $PSScriptRoot\config.ps1

#### VARIABLES ####
$Logfile = $FullBackupLogFile

#### FUNCTIONS ####
function WriteLog([string]$LogString, [bool]$PrintLog){
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
    if ($PrintLog){
        Write-Output($LogString)
    }
}
function Test-Variable([String]$VariableName, [String]$VariableValue){
    if (-Not $VariableValue){
        $MessageText = "Environment variable $VariableName is not defined as expected. Execute the script 'install_scripts.ps1' to set the environment variables correctly."
        WriteLog $MessageText $true
    }   
}

# Verify the environment variables
WriteLog "#################################################################################" $false
WriteLog "Verifying if expected Environment variables are defined..." $true
Test-Variable 'DB_PATH' "$Env:DB_PATH"
Test-Variable 'DB_USER' "$Env:DB_USER"
Test-Variable 'DB_PWD' "$Env:DB_PWD"
Test-Variable 'BACKUP_PATH' "$Env:BACKUP_PATH"

$FormatedDate = (Get-Date).toString("yyyyMMdd")

# Check if the path "last_backup" exists and create it if doesn't.
#WriteLog("Checking if last_backup\full_$FormatedDate folder exists... If it exists, delete its files, otherwise create this one.")
#If (-Not (Test-Path "$Env:BACKUP_PATH\last_backup\full_$FormatedDate")){ 
#    New-Item -Path "$Env:BACKUP_PATH\last_backup\full_$FormatedDate" -ItemType Directory
#    WriteLog("Folder 'last_backup\full_$FormatedDate' created successfully.")
#} else {
#    WriteLog("Deleting previous full backup...")
#    Get-ChildItem -Path "$Env:BACKUP_PATH\last_backup\full_$FormatedDate\*" -Recurse | Remove-Item -Recurse
#    WriteLog("Previous full backup deleted successfully.")
#}

# Move all files to last_backup directory.
#WriteLog("Moving previous full backup to folder last_backup\full_$FormatedDate...")
#If (Test-Path "$Env:BACKUP_PATH\full_$FormatedDate"){
#    Get-ChildItem -Path "$Env:BACKUP_PATH\full\*" -Recurse | Move-Item -Destination "$Env:BACKUP_PATH\last_backup\full\"
#    WriteLog("Previous full backup moved successfully.")
#}

# Verify if full backup directory exists and create it if doesn't.
$MessageText = "Folder full_$FormatedDate created successfully."
#Write-Output $MessageText
WriteLog $MessageText $true

WriteLog "Verifying if folder full_$FormatedDate exists and create it if doesn't..." $true
If (-Not (Test-Path "$Env:BACKUP_PATH\full_$FormatedDate")){
    New-Item -Path "$Env:BACKUP_PATH\full_$FormatedDate" -ItemType Directory
    $MessageText = "Folder full_$FormatedDate created successfully."
    #Write-Output $MessageText
    WriteLog $MessageText $true
} else {
    WriteLog "Deleting previous full backup..." $true
    Get-ChildItem -Path "$Env:BACKUP_PATH\full_$FormatedDate\*" -Recurse | Remove-Item -Recurse
    WriteLog "Previous full backup deleted successfully." $true
}

# Full backup
$program = "& " + "'${Env:DB_PATH}" + "\bin\mariabackup' --backup --target-dir=$Env:BACKUP_PATH\full_$FormatedDate --user=$Env:DB_USER --password=$Env:DB_PWD"

# if compress flag is true
if ($CompressFullBackup){   
    $program += " --stream=xbstream | Compress-Archive -DestinationPath $Env:BACKUP_PATH\full_$FormatedDate\mariadb_fullbackup.zip"
}

try{
    # Full Backup
    WriteLog "Running MariaDB full backup..." $true
    Invoke-Expression "$program"
    $MessageText = "MariaDB full backup generated successfully."
    #Write-Output $MessageText
    WriteLog $MessageText $true
} catch {
    $MessageText = "An error occurs when executing MariaDB full backup."
    #Write-Error $MessageText
    WriteLog $MessageText $true
} 

