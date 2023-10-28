Write-Host -ForegroundColor Green "Starting Zero Touch Setup"

Start-Sleep -Seconds 1
Write-Host -ForegroundColor Green "Starting AFCA OSDCloud Setup"


Write-Host -ForegroundColor Green "Starting Automated OS Installation Process"

#Start-OSDCloud -ImageFileURL "D:\OSDCloud\0S\Win11_22H2_Enterprise.wim" -OSImageIndex "1" -ZTI

Start-OSDCloud  -FindImageFile -OSLanguage en-us -OSEdition Enterprise -OSActivation Volume -ZTI

#Restart from WinPE

Write-Host -ForegroundColor Green "Restarting in 3 seconds!"

Start-Sleep -Seconds 3

wpeutil reboot
