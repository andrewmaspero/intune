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

    # Define a policy that bypasses all SSL certificate checks
    Add-Type -TypeDefinition @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    # Send the request
    $response = Invoke-RestMethod -Method Post -Uri $url -Body $bodyJson -ContentType "application/json"

    # Reset the certificate policy
    [System.Net.ServicePointManager]::CertificatePolicy = $null

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

    # Define a policy that bypasses all SSL certificate checks
    Add-Type -TypeDefinition @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    # Create a new WebClient object
    $webClient = New-Object System.Net.WebClient

    # Download each file
    foreach ($fileName in $fileNames) {
        $fileUrl = $url + $fileName
        $destinationPath = Join-Path -Path $destination -ChildPath $fileName

        # Download the file
        $webClient.DownloadFile($fileUrl, $destinationPath)
    }

    # Reset the certificate policy
    [System.Net.ServicePointManager]::CertificatePolicy = $null
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

Send-EventUpdate -eventStage "Loading OSD Modules" -eventStatus "COMPLETED"

Write-Host -ForegroundColor Green "Starting AFCA OSDCloud Setup"

Start-Sleep -Seconds 2

Send-EventUpdate -eventStage "Starting Automated OS Installation Process" -eventStatus "IN_PROGRESS"

Write-Host -ForegroundColor Green "Starting Automated OS Installation Process"

#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================
function Get-ImageChecksum {
    param (
        [string]$ChecksumFileName,
        [string]$DownloadPath = "X:\Temp"
    )

    if (-not (Test-Path -Path $DownloadPath)) {
        New-Item -ItemType Directory -Path $DownloadPath -Force
        Write-Host "Created download path: $DownloadPath" -ForegroundColor Green
    }

    # Download the checksum file
    $LocalChecksumPath = Join-Path -Path $DownloadPath -ChildPath $ChecksumFileName
    Start-DownloadingFiles -fileNames $ChecksumFileName -destination $LocalChecksumPath
    Write-Host "Checksum file downloaded to $LocalChecksumPath" -ForegroundColor Green

    # Read the checksum value from the file
    $ChecksumValue = Get-Content -Path $LocalChecksumPath -Raw
    return $ChecksumValue.Trim()  # Trim to remove any extraneous whitespace
}

function Start-DownloadImageOrc {
    param (
        [string]$ImageFileNameOnWebServer,
        [string]$ChecksumFileNameOnWebServer,
        [string]$Destination,
        [string]$USBPath
    )

    # Ensure destination directory exists
    $DestinationDirectory = [System.IO.Path]::GetDirectoryName($Destination)
    if (-not (Test-Path $DestinationDirectory)) {
        New-Item -Path $DestinationDirectory -ItemType Directory -Force
        Write-Host "Created destination directory: $DestinationDirectory" -ForegroundColor Green
    }

    # Download image
    Start-DownloadingFiles -fileNames $ImageFileNameOnWebServer -destination $Destination
    Write-Host "Image downloaded to $Destination" -ForegroundColor Green

    # Download checksum file
    $ChecksumFileDestination = Join-Path -Path $DestinationDirectory -ChildPath $ChecksumFileNameOnWebServer
    Start-DownloadingFiles -fileNames $ChecksumFileNameOnWebServer -destination $ChecksumFileDestination
    Write-Host "Checksum file downloaded to $ChecksumFileDestination" -ForegroundColor Green

    # Copy the image to USB if USBPath is provided
    if ($USBPath) {
        $USBTargetPath = Join-Path -Path $USBPath -ChildPath "OSDCloud\OS\$ImageFileNameOnWebServer"
        Copy-Item -Path $Destination -Destination $USBTargetPath -Force
        Write-Host "Image copied to USB at $USBTargetPath" -ForegroundColor Green
        return $USBTargetPath
    }

    return $Destination
}

function Start-CheckAndCacheImageToUSBOrc {
    param (
        [string]$ImageFileName,
        [string]$ChecksumFileName,
        [int]$MinFreeSpaceGB = 5 
    )

    $USBDrive = Get-PSDrive -PSProvider FileSystem | Where-Object {
        ($_.Root -match "^.:\\") -and
        ($_.Free -gt ($MinFreeSpaceGB * 1GB)) -and
        ($_.Name -match "OSDCloud|BHIMAGE")
    } | Select-Object -First 1

    if ($USBDrive) {
        Write-Host "USB drive found: $($USBDrive.Root), checking for cached image..." -ForegroundColor Cyan

        $CachedImagePath = Join-Path -Path $USBDrive.Root -ChildPath "OSDCloud\OS\$ImageFileName"
        $CachedChecksumPath = [System.IO.Path]::ChangeExtension($CachedImagePath, ".sha256")

        if (Test-Path $CachedImagePath -and Test-Path $CachedChecksumPath) {
            Write-Host "Cached image and checksum file found. Verifying integrity..." -ForegroundColor Cyan

            $CachedChecksum = Get-Content -Path $CachedChecksumPath -Raw

            # Get the checksum from the web server
            $RemoteChecksum = Get-ImageChecksum -ChecksumFileName $ChecksumFileName

            if ($CachedChecksum.Trim() -eq $RemoteChecksum) {
                Write-Host "Image hash matches the remote checksum. Using cached image." -ForegroundColor Green
                return $CachedImagePath
            } else {
                Write-Host "Image hash does not match the remote checksum. Downloading and updating image on USB." -ForegroundColor Yellow
                return Start-DownloadImageOrc -ImageFileNameOnWebServer $ImageFileName -ChecksumFileNameOnWebServer $ChecksumFileName -Destination "C:\OSDCloud\OS" -USBPath $USBDrive.Root
            }
        } else {
            Write-Host "Image or checksum not found on USB. Downloading and caching it." -ForegroundColor Yellow
            return Start-DownloadImageOrc -ImageFileNameOnWebServer $ImageFileName -ChecksumFileNameOnWebServer $ChecksumFileName -Destination "C:\OSDCloud\OS" -USBPath $USBDrive.Root
        }
    } else {
        Write-Host "No suitable USB drive found with sufficient space. Downloading image to local storage." -ForegroundColor Red
        return Start-DownloadImageOrc -ImageFileNameOnWebServer $ImageFileName -ChecksumFileNameOnWebServer $ChecksumFileName -Destination "C:\OSDCloud\OS"
    }
}

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

# URL and expected SHA1 hash
$ImageFileName = "Windows11_23H2_LATEST_ALLDRIVERS.wim"
$ChecksumFileName = "Windows11_23H2_LATEST_ALLDRIVERS.sha256"
$ImagePath = Start-CheckAndCacheImageToUSBOrc -ImageFileName $ImageFileName -ChecksumFileName $ChecksumFileName

Start-OSDCloud -ImageFile $ImagePath -ImageIndex 1 -ZTI

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
