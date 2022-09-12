#### EXTERNAL FILES ####
. $PSScriptRoot\config.ps1
. $PSScriptRoot\util.ps1

#### VARIABLES ####
$Logfile = $FullBackupLogFile

#### FUNCTIONS ####
filter Compress-Folder{
    $Path = $PSItem
    # Verify if temp directory exists and create this if doesn't
    If (-Not (Test-Path "$Env:BACKUP_PATH\temp")){ 
        New-Item -Path "$Env:BACKUP_PATH\temp" -ItemType Directory
    }

    # Verify if directory has files excluding zip, if doesn't exits
    If (Test-Path "$Env:BACKUP_PATH\$Path\*" -Exclude "*.zip"){    
        WriteLog "Compressing $Path..." $true
        $command = "Compress-Archive -Path $Env:BACKUP_PATH\$Path\* -DestinationPath $Env:BACKUP_PATH\temp\mariadb_fullbackup_$Path.zip"
        Invoke-Expression $command
        WriteLog "Deleting compressed files into folder $Env:BACKUP_PATH\$Path." $true
        Get-ChildItem -Path "$Env:BACKUP_PATH\$Path\*" -Recurse | Remove-Item -Recurse
        WriteLog "Compressed files deleted." $true
        Move-Item -Path "$Env:BACKUP_PATH\temp\mariadb_fullbackup_$Path.zip" -Destination "$Env:BACKUP_PATH\$Path\mariadb_fullbackup_$Path.zip"
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

WriteLog "Verifying if folder full_$FormatedDate exists and create it if doesn't..." $true
If (-Not (Test-Path "$Env:BACKUP_PATH\full_$FormatedDate")){
    New-Item -Path "$Env:BACKUP_PATH\full_$FormatedDate" -ItemType Directory
    $MessageText = "Folder full_$FormatedDate created successfully."
    WriteLog $MessageText $true
} else {
    WriteLog "Previous full backup folder $Env:BACKUP_PATH\full_$FormatedDate exists. Deleting the folder..." $true
    Get-ChildItem -Path "$Env:BACKUP_PATH\full_$FormatedDate\*" -Recurse | Remove-Item -Recurse
    WriteLog "Previous full backup folder deleted successfully." $true
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
    try{
        Get-Item "$Env:BACKUP_PATH\full_*" -Exclude "full_$FormatedDate" | Split-Path -Leaf | Compress-Folder
    } catch {
        WriteLog "Error running compressing procedure." $true
    }
}

WriteLog "End of MariaDB backup full routine." $true
