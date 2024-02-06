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

Send-EventUpdate -eventStage "Loading OSD Modules" -eventStatus "COMPLETED"



Write-Host -ForegroundColor Green "Starting AFCA OSDCloud Setup"

Start-Sleep -Seconds 2

Send-EventUpdate -eventStage "Starting Automated OS Installation Process" -eventStatus "IN_PROGRESS"

Write-Host -ForegroundColor Green "Starting Automated OS Installation Process"

#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================
$Params = @{
    OSVersion = "Windows 11"
    OSBuild = "22H2"
    OSEdition = "Enterprise"
    OSLanguage = "en-us"
    OSLicense = "Volume"
    ZTI = $true
    Firmware = $false
}

Start-OSDCloud @Params

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
