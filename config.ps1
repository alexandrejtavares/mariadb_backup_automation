$LogRetention = 30 #Days
$IncrementalBackupRetention = 3 #Days
$FullBackupRetention = 3 #Days
$FullBackupLogFile = "$PSScriptRoot\mariadb_fullbackup.log"
$IncrementalBackupLogFile = "$PSScriptRoot\mariadb_incrementalbackup.log"
$CompressFullBackup = $true