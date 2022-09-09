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
filter Compress-Folder{
    $Path = $PSItem
    # Verify if temp directory exists and create this if doesn't
    If (-Not (Test-Path "$Env:BACKUP_PATH\temp")){ 
        New-Item -Path "$Env:BACKUP_PATH\temp" -ItemType Directory
    }

    # Verify if directory has files excluding zip, if doesn't exits
    If (-Not (Test-Path "$Env:BACKUP_PATH\$Path\*" -Exclude "*.zip")){ 
        Exit
    }
    WriteLog "Compressing $Path." $true
    $command = "Compress-Archive -Path $Env:BACKUP_PATH\$Path\* -DestinationPath $Env:BACKUP_PATH\temp\mariadb_fullbackup_$Path.zip"
    Invoke-Expression $command
    WriteLog "Deleting compressed files..." $true
    Get-ChildItem -Path "$Env:BACKUP_PATH\$Path\*" -Recurse | Remove-Item -Recurse
    WriteLog "Compressed files deleted." $true
    Move-Item -Path "$Env:BACKUP_PATH\temp\mariadb_fullbackup_$Path.zip" -Destination "$Env:BACKUP_PATH\$Path\mariadb_fullbackup_$Path.zip"
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
    WriteLog $MessageText $true
} else {
    WriteLog "Deleting previous full backup..." $true
    Get-ChildItem -Path "$Env:BACKUP_PATH\full_$FormatedDate\*" -Recurse | Remove-Item -Recurse
    WriteLog "Previous full backup deleted successfully." $true
}

# Full backup
$command = "& " + "'${Env:DB_PATH}" + "\bin\mariabackup' --backup --target-dir=$Env:BACKUP_PATH\full_$FormatedDate --user=$Env:DB_USER --password=$Env:DB_PWD"

try{
    # Full Backup
    WriteLog "Running MariaDB full backup..." $true
    Invoke-Expression "$command"
    $MessageText = "MariaDB full backup generated successfully."
    WriteLog $MessageText $true
} catch {
    $MessageText = "An error occurs when executing MariaDB full backup."
    WriteLog $MessageText $true
} 

# if compress flag is true compress previous backups
if ($CompressFullBackup){   
    WriteLog "Compressing MariaDB full backup previous files..." $true
    try{
        Get-Item "$Env:BACKUP_PATH\full_*" -Exclude "full_$FormatedDate" | Split-Path -Leaf | Compress-Folder
        WriteLog "MariaDB full backup previous files compressed successfuly." $true
    } catch {
        WriteLog "Error compressing mariadb full backup files." $true
    }
}

WriteLog "End of MariaDB backup full routine." $true
