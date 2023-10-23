Write-Host -ForegroundColor Green “Starting Zero Touch Setup”

Start-Sleep -Seconds 1
Write-Host -ForegroundColor Green “Starting AFCA OSDCloud Setup”

#Make sure I have the latest OSD Content
Write-Host -ForegroundColor Green “Updating OSD PowerShell Module”

Install-Module OSD -Force

Write-Host -ForegroundColor Green “Importing OSD PowerShell Module”

Import-Module OSD -Force

#Start OSDCloud ZTI the RIGHT way

Write-Host -ForegroundColor Green “Start OSDCloud”

Start-OSDCloud -OSName 'D:\OSDCloud\OS\Win11_22H2_Enterprise.wim' -OSLanguage en-us -OSEdition Enterprise -OSActivation Volume -ZTI

#Restart from WinPE

Write-Host -ForegroundColor Green “Restarting in 3 seconds!”

Start-Sleep -Seconds 3

wpeutil reboot
