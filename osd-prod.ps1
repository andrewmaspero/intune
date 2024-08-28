#================================================
#   [OSDCloud]
#================================================
function Send-EventUpdate {
    param(
        [Parameter(Mandatory=$true)] [string] $eventStage,
        [Parameter(Mandatory=$true)] [string] $eventStatus
    )

    # Get system info
    $bios = Get-CimInstance -ClassName Win32_BIOS
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $physicalMemory = Get-CimInstance -ClassName Win32_PhysicalMemory
    $baseboard = Get-CimInstance -ClassName Win32_BaseBoard
    $processor = Get-CimInstance -ClassName Win32_Processor

    $systemInfo = [PSCustomObject]@{
        'serial_number' = $bios.SerialNumber
        'manafacture'  = $bios.Manufacturer
        'model'         = $computerSystem.Model
        'ram'     = "{0:N2} GB" -f (($physicalMemory.Capacity | Measure-Object -Sum).Sum / 1GB)  # Convert memory to string and append " GB"
        'baseboard' = $baseboard.Product
        'processor' = $processor.Name
    }

    # Endpoint URL
    $url = "https://autopro.afca.org.au/api/osdcloud-event-updates/"

    $body = @{
        "serial_number" = $systemInfo.serial_number
        "event_stage" = $eventStage
        "event_status" = $eventStatus
        "manufacture" = $systemInfo.manafacture
        "model" = $systemInfo.model
        "baseboard" = $systemInfo.baseboard
        "memory" = $systemInfo.ram
        "processor" = $systemInfo.processor
    }
    $bodyJson = $body | ConvertTo-Json

    # Send the request
    $response = Invoke-RestMethod -Method Post -Uri $url -Body $bodyJson -ContentType "application/json"


    return $response
}

#Start OSD Commands

Send-EventUpdate -eventStage "Starting Up Setup Files" -eventStatus "IN_PROGRESS"

Start-Sleep -Seconds 3

function New-Directory {
    param (
        [string]$FolderPath
    )
    If (!(Test-Path -Path $FolderPath)) {
        New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
    }
}

# Create script folder
New-Directory -FolderPath "X:\temp"

#Function to download files from local server
function Start-DownloadingFiles {
    param (
        [string]$url = "https://autopro.afca.org.au/hosted-files/",
        [string]$destination = "X:\temp",
        [string[]]$fileNames 
    )

    # Create a new WebClient object
    $webClient = New-Object System.Net.WebClient

    # Download each file
    foreach ($fileName in $fileNames) {
        $fileUrl = $url + $fileName
        $destinationPath = Join-Path -Path $destination -ChildPath $fileName

        # Download the file
        $webClient.DownloadFile($fileUrl, $destinationPath)
    }

}

$DLfileNames = @(
    "ws_oobe_agent.exe",
    "ws_user_assignment.exe",
    "OOBE-Startup-Script.ps1",
    "Post-Install-Script.ps1",
    "SendKeysSHIFTnF10.ps1",
    "service_ui.exe",
    "reboot_agent.exe",
    "nssm.exe",
    "SpecialiseTaskScheduler.ps1",
    "RebootAgent-Service-Manager.ps1"
)
Start-DownloadingFiles -fileNames $DLfileNames

Send-EventUpdate -eventStage "Starting Up Setup Files" -eventStatus "COMPLETED"
Start-Sleep -Seconds 2

#Assign PC to User
Start-Process "X:\temp\ws_user_assignment.exe" -ArgumentList "ArgumentsForExecutable" -Wait

Start-Sleep -Seconds 1

#Start OSD Commands
Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"

Send-EventUpdate -eventStage "Loading OSD Modules" -eventStatus "IN_PROGRESS"

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"

Import-Module OSD -Force

function Send-EventUpdate {
    param(
        [Parameter(Mandatory=$true)] [string] $eventStage,
        [Parameter(Mandatory=$true)] [string] $eventStatus
    )

    # Get system info
    $bios = Get-CimInstance -ClassName Win32_BIOS
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $physicalMemory = Get-CimInstance -ClassName Win32_PhysicalMemory
    $baseboard = Get-CimInstance -ClassName Win32_BaseBoard
    $processor = Get-CimInstance -ClassName Win32_Processor

    $systemInfo = [PSCustomObject]@{
        'serial_number' = $bios.SerialNumber
        'manafacture'  = $bios.Manufacturer
        'model'         = $computerSystem.Model
        'ram'     = "{0:N2} GB" -f (($physicalMemory.Capacity | Measure-Object -Sum).Sum / 1GB)  # Convert memory to string and append " GB"
        'baseboard' = $baseboard.Product
        'processor' = $processor.Name
    }

    # Endpoint URL
    $url = "https://autopro.afca.org.au/api/osdcloud-event-updates/"

    $body = @{
        "serial_number" = $systemInfo.serial_number
        "event_stage" = $eventStage
        "event_status" = $eventStatus
        "manufacture" = $systemInfo.manafacture
        "model" = $systemInfo.model
        "baseboard" = $systemInfo.baseboard
        "memory" = $systemInfo.ram
        "processor" = $systemInfo.processor
    }
    $bodyJson = $body | ConvertTo-Json

    # Send the request
    $response = Invoke-RestMethod -Method Post -Uri $url -Body $bodyJson -ContentType "application/json"

    return $response
}

Send-EventUpdate -eventStage "Loading OSD Modules" -eventStatus "COMPLETED"



Write-Host -ForegroundColor Green "Starting AFCA OSDCloud Setup"

Start-Sleep -Seconds 2

Send-EventUpdate -eventStage "Starting Automated OS Installation Process" -eventStatus "IN_PROGRESS"

Write-Host -ForegroundColor Green "Starting Automated OS Installation Process"

#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================
#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    updateDiskDrivers              = [bool]$False
    updateFirmware                 = [bool]$False
    updateNetworkDrivers           = [bool]$False
    updateSCSIDrivers              = [bool]$False
    captureScreenshots             = [bool]$False
    SyncMSUpCatDriverUSB           = [bool]$False
    HPIAALL                        = [bool]$False
    HPIADrivers                    = [bool]$False
    HPIAFirmware                   = [bool]$False
    HPIASoftware                   = [bool]$False
    HPTPMUpdate                    = [bool]$False
    HPBIOSUpdate                   = [bool]$False
    MSCatalogFirmware              = [bool]$False
    MSCatalogDiskDrivers           = [bool]$False
    MSCatalogNetDrivers            = [bool]$False
    MSCatalogScsiDrivers           = [bool]$False
    ScreenshotCapture              = [bool]$False
    ScreenshotPath                 = [string]"X:\Temp\Screenshots"
}

$URL = "https://autopro.afca.org.au/hosted-files/Windows11_23H2_LATEST_ALLDRIVERS.wim"

Start-OSDCloud -ImageFileUrl $URL -ImageIndex 1 -ZTI

function Send-EventUpdate {
    param(
        [Parameter(Mandatory=$true)] [string] $eventStage,
        [Parameter(Mandatory=$true)] [string] $eventStatus
    )

    # Get system info
    $bios = Get-CimInstance -ClassName Win32_BIOS
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $physicalMemory = Get-CimInstance -ClassName Win32_PhysicalMemory
    $baseboard = Get-CimInstance -ClassName Win32_BaseBoard
    $processor = Get-CimInstance -ClassName Win32_Processor

    $systemInfo = [PSCustomObject]@{
        'serial_number' = $bios.SerialNumber
        'manafacture'  = $bios.Manufacturer
        'model'         = $computerSystem.Model
        'ram'     = "{0:N2} GB" -f (($physicalMemory.Capacity | Measure-Object -Sum).Sum / 1GB)  # Convert memory to string and append " GB"
        'baseboard' = $baseboard.Product
        'processor' = $processor.Name
    }

    # Endpoint URL
    $url = "https://autopro.afca.org.au/api/osdcloud-event-updates/"

    $body = @{
        "serial_number" = $systemInfo.serial_number
        "event_stage" = $eventStage
        "event_status" = $eventStatus
        "manufacture" = $systemInfo.manafacture
        "model" = $systemInfo.model
        "baseboard" = $systemInfo.baseboard
        "memory" = $systemInfo.ram
        "processor" = $systemInfo.processor
    }
    $bodyJson = $body | ConvertTo-Json

    # Send the request
    $response = Invoke-RestMethod -Method Post -Uri $url -Body $bodyJson -ContentType "application/json"

    return $response
}

#Installation Finished
Send-EventUpdate -eventStage "Starting Automated OS Installation Process" -eventStatus "COMPLETED"

function Copy-Everything {
    param (
        [string]$source,
        [string]$destination
    )

    # Ensure the destination directory exists
    if (!(Test-Path -Path $destination)) {
        New-Item -Path $destination -ItemType Directory -Force | Out-Null
    }

    # Copy everything from the source directory to the destination directory
    Copy-Item -Path "$source\*" -Destination $destination -Recurse -Force
}

Copy-Everything -source "X:\temp" -destination "C:\temp"

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
powershell.exe -Command "Set-ExecutionPolicy RemoteSigned -Force"
powershell.exe -Command "Start-Process powershell -ArgumentList '-File C:\temp\SpecialiseTaskScheduler.ps1' -Wait"
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force
Start-Sleep -Seconds 1
#=======================================================================
#   Restart-Computer
#=======================================================================
Send-EventUpdate -eventStage "Restarting Device" -eventStatus "IN_PROGRESS"
Write-Host  -ForegroundColor Green "Restarting in 5 seconds!"
Start-Sleep -Seconds 5
wpeutil reboot
