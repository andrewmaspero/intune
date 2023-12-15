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
    $url = "https://autoprovision.afca.org.au/api/osdcloud-event-updates/"

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

Send-EventUpdate -eventStage "OSD Cloud Starting Up" -eventStatus "IN_PROGRESS"

Start-Sleep -Seconds 3

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"

Send-EventUpdate -eventStage "Loading OSD Modules" -eventStatus "IN_PROGRESS"

Install-Module OSD -Force

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
    $url = "https://autoprovision.afca.org.au/api/osdcloud-event-updates/"

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
    SkipAutopilot = $true
}
Start-OSDCloud @Params

#Start-OSDCloud -FindImageFile -OSImageIndex "3" -ZTI

function Copy-FromBootImage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $FileName
    )
    process {
        $SourceFilePath = Join-Path -Path "E:\OSDCloud\Scripts" -ChildPath $FileName
        $DestinationFolderPath = "C:\temp"
        if (-not $env:SystemDrive) {
            Write-Error "This script must be run in a WinPE environment."
            return
        }
        try {
            if (Test-Path -Path $SourceFilePath) {
                if (-not (Test-Path -Path $DestinationFolderPath)) {
                    New-Item -ItemType Directory -Path $DestinationFolderPath | Out-Null
                }
                $fullDestinationPath = Join-Path -Path $DestinationFolderPath -ChildPath $FileName
                Copy-Item -Path $SourceFilePath -Destination $fullDestinationPath -Force -ErrorAction Stop
                Write-Output "File '$SourceFilePath' has been copied to '$fullDestinationPath'"
            } else {
                throw "Source file '$SourceFilePath' does not exist."
            }
        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
}

function Copy-FolderToTemp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $SourceFolder
    )
    process {
        $DestinationFolderPath = "C:\temp"

        if (-not $env:SystemDrive) {
            Write-Error "This script must be run in a WinPE environment."
            return
        }

        try {
            if (Test-Path -Path $SourceFolder -PathType Container) {
                $fullDestinationPath = $DestinationFolderPath
                if (-not (Test-Path -Path $fullDestinationPath)) {
                    New-Item -ItemType Directory -Path $fullDestinationPath | Out-Null
                }
                Copy-Item -Path $SourceFolder -Destination $fullDestinationPath -Recurse -Force -ErrorAction Stop
                Write-Output "Folder '$SourceFolder' has been copied to '$fullDestinationPath'"
            } else {
                throw "Source folder '$SourceFolder' does not exist or is not a directory."
            }
        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
}

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
    $url = "https://autoprovision.afca.org.au/api/osdcloud-event-updates/"

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

function Create-Folder {
    param (
        [string]$FolderPath
    )
    If (!(Test-Path -Path $FolderPath)) {
        New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
    }
}

# Create script folder
Create-Folder -FolderPath "C:\temp"

#Assign PC to User
Start-Process "E:\OSDCloud\Scripts\OSDCloud-Assign-User.exe" -ArgumentList "ArgumentsForExecutable" -Wait
Start-Sleep -Seconds 1

#Copy Files from Image to C: Drive
Copy-FromBootImage -FileName "SpecialiseTaskScheduler.ps1"
Start-Sleep -Seconds 1
Copy-FromBootImage -FileName "OOBE-Startup-Script.ps1"
Start-Sleep -Seconds 1
Copy-FromBootImage -FileName "SendKeysSHIFTnF10.ps1"
Start-Sleep -Seconds 1
Copy-FromBootImage -FileName "Post-Install-Script.ps1"
Start-Sleep -Seconds 1
Copy-FromBootImage -FileName "ServiceUI.exe"
Start-Sleep -Seconds 1
Copy-FromBootImage -FileName "OOBE-Agent.exe"

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
