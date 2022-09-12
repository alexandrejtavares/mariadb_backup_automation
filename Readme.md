# MariaDB - Backup Automation #  

Version: 1.0 - 29/08/2022

## Author ##

### Alexandre Tavares ###

- E-mail: alexandrejtavares@yahoo.com.br
- Linkedin: <https://linkedin.com/in/alexandrejtavares>

## Requirements ##

1) Administrator user to run the automation Scheduled Tasks with the Local Security Policy *Log on as a batch job* granted.
2) Folder to save the MariaDB backups.
3) Folder to save the scripts.

## Instructions ##

1) Save the scripts in a folder in MariaDB server:  
    - install_scripts.ps1  
    - mariadb_fullbackup.ps1  
    - mariadb_incrementalbackup.ps1  
2) As administrator, run the script *install_scripts.ps1* in PowerShell.  
3) Insert the attributes below:  
    - **db_path** -> MariaDB path.  
    - **db_user** -> MariaDB user with backup authority.  
    - **db_pwd** ->  MariaDB backup user's password.  
    - **backup_path** -> Folder to save backups (Must exists).  
    - **batch_user** -> Windows Administrator user with *Log on as a batch job* security policy granted.  
    - **batch_user_pwd** -> Windows batch user's password.  
4) The script will configure all requirements and will create the automation tasks that will run the backups automaticaly:  
   - Set all environment variables needed by automation.  
   - Create a task in Windows Task Scheduler to run the full backup daily, at 1AM.  
   - Create a task in Windows Task Scheduler to run the incremental backup hourly.  

## Tips ##

- Unblock downloaded script to run in PowerShell:
  
    `Get-ChildItem -Filter *.ps1 | Unblock-File`
