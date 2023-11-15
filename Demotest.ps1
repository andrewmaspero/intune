Write-Host -ForegroundColor Green "Starting Zero Touch Setup"

Start-Sleep -Seconds 1
Write-Host -ForegroundColor Green "Starting AFCA OSDCloud Setup"


Write-Host -ForegroundColor Green "Starting Automated OS Installation Process"

#Start-OSDCloud -ImageFileURL "D:\OSDCloud\0S\Win11_22H2_Enterprise.wim" -OSImageIndex "1" -ZTI

Start-OSDCloud -FindImageFile -OSImageIndex "3" -ZTI

function Create-ScriptFolder {
    param (
        [string]$FolderPath
    )
    If (!(Test-Path -Path $FolderPath)) {
        New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
    }
}

function Create-ScheduledTask {
    param (
        [string]$TaskName,
        [string]$TaskDescription,
        [string]$TriggerDelay,
        [string]$ActionPath,
        [string]$ActionArguments
    )
    $ShedService = New-Object -comobject 'Schedule.Service'
    $ShedService.Connect()

    $Task = $ShedService.NewTask(0)
    $Task.RegistrationInfo.Description = $TaskDescription
    $Task.Settings.Enabled = $true
    $Task.Settings.AllowDemandStart = $true

    $trigger = $Task.Triggers.Create(9)
    $trigger.Delay = $TriggerDelay
    $trigger.Enabled = $true

    $action = $Task.Actions.Create(0)
    $action.Path = $ActionPath
    $action.Arguments = $ActionArguments

    $taskFolder = $ShedService.GetFolder("\")
    $taskFolder.RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $NULL, 5)
}

# Set script folder paths
$scriptFolderPath = "$env:SystemDrive\OSDCloud\Scripts"

# Create script folder
Create-ScriptFolder -FolderPath $scriptFolderPath

# Example of creating a scheduled task
Create-ScheduledTask -TaskName "Start OOBE AFCA Agent" -TaskDescription "This task is used to auto start the OOBE Agent to automate user driven provisioning" -TriggerDelay 'PT60S' -ActionPath "$scriptFolderPath\OOBE-Task.exe" -ActionArguments '-SomeArguments'

#Copy .exe to file


#Restart from WinPE

Write-Host -ForegroundColor Green "Restarting in 3 seconds!"

Start-Sleep -Seconds 3

wpeutil reboot
