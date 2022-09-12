#### CONFIG FILE ####
. $PSScriptRoot\config.ps1

filter Compress-Folder{
    Write-Output "Initializing compress function..."
    $Path = $PSItem
    Write-Output $Path    
    # Verify if temp directory exists and create this if doesn't
    If (-Not (Test-Path "$Env:BACKUP_PATH\temp")){ 
        New-Item -Path "$Env:BACKUP_PATH\temp" -ItemType Directory
    }

    # Verify if directory has files excluding zip, if doesn't exits
    If (Test-Path "$Env:BACKUP_PATH\$Path\*" -Exclude "*.zip"){ 
        Write-Output "Compressing $Path..."
        $command = "Compress-Archive -Path $Env:BACKUP_PATH\$Path\* -DestinationPath $Env:BACKUP_PATH\temp\mariadb_fullbackup_$Path.zip"
        Invoke-Expression $command
        Write-Output "Deleting compressed files into folder $Env:BACKUP_PATH\$Path."
        Get-ChildItem -Path "$Env:BACKUP_PATH\$Path\*" -Recurse | Remove-Item -Recurse
        Write-Output "Compressed files deleted."
        Move-Item -Path "$Env:BACKUP_PATH\temp\mariadb_fullbackup_$Path.zip" -Destination "$Env:BACKUP_PATH\$Path\mariadb_fullbackup_$Path.zip"
    } else {
        Write-Output "No previous backup files to compress."
    }
}

# Create incremental backup task in Task Scheduler
$FormatedDate = (Get-Date).toString("yyyyMMdd")
Write-Output $FormatedDate

Write-Output $CompressFullBackup

Write-Output "Compressing MariaDB full backup previous files..."
try{
    Get-Item "$Env:BACKUP_PATH\full_*" -Exclude "full_$FormatedDate" | Split-Path -Leaf | Compress-Folder
    Write-Output  "MariaDB full backup previous files compressed successfuly."
} catch {
    Write-Output "Error compressing mariadb full backup files."
}

Write-Output "Full backups:"

Get-Item "$Env:BACKUP_PATH\full_*" -Exclude "full_$FormatedDate" | Split-Path -Leaf
