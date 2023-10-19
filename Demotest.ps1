Write-Host -ForegroundColor Green “Starting Zero Touch Setup”

Start-Sleep -Seconds 5
Write-Host -ForegroundColor Green “Starting AFCA OSDCloud Setup”

#Change Display Resolution for Virtual Machine

if ((Get-MyComputerModel) -match ‘Virtual’) {

Write-Host -ForegroundColor Green “Setting Display Resolution to 1600x”

Set-DisRes 1600

}

#Make sure I have the latest OSD Content

Write-Host -ForegroundColor Green “Updating OSD PowerShell Module”

Install-Module OSD -Force

Write-Host -ForegroundColor Green “Importing OSD PowerShell Module”

Import-Module OSD -Force

#Start OSDCloud ZTI the RIGHT way

Write-Host -ForegroundColor Green “Start OSDCloud”

Start-OSDCloud -OSName 'Windows 11 22H2 x64' -OSLanguage en-us -OSEdition Enterprise -OSActivation Volume -ZTI

#Restart from WinPE

Write-Host -ForegroundColor Green “Restarting in 5 seconds!”

Start-Sleep -Seconds 5

wpeutil reboot
