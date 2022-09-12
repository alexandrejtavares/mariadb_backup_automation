#### FUNCTIONS ####
function WriteLog([string]$LogString, [bool]$PrintLog){
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $LogFile -value $LogMessage
    if ($PrintLog){
        Write-Output($LogString)
    }
}

function Test-Variable([String]$VariableName, [String]$VariableValue) {
    if (-Not $VariableValue) {
        $MessageText = "Environment variable $VariableName is not defined as expected. Execute the script 'install_scripts.ps1' to set the environment variables correctly."
        WriteLog $MessageText $true
    }
}
