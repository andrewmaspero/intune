Write-Host -ForegroundColor Green "Starting Zero Touch Setup"

Start-Sleep -Seconds 1
Write-Host -ForegroundColor Green "Starting AFCA OSDCloud Setup"


Write-Host -ForegroundColor Green "Starting Automated OS Installation Process"

Start-OSDCloud  -FindImageFile -OSName 'Win11_22H2_Enterprise.wim' -OSLanguage en-us -OSEdition Enterprise -OSActivation Volume -ZTI

#Restart from WinPE

Write-Host -ForegroundColor Green “Restarting in 3 seconds!”

Start-Sleep -Seconds 3

wpeutil reboot
