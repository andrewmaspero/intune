#================================================
#   [OSDCloud] Update Module
#================================================

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"

Import-Module OSD -Force

Write-Host -ForegroundColor Green "Starting AFCA OSDCloud Setup"

Start-Sleep -Seconds 1

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
#Start-OSDCloud @Params

Start-OSDCloud -FindImageFile -OSImageIndex "3" -ZTI

function Copy-FromBootImage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $FileName
    )
    process {
        $SourceFilePath = Join-Path -Path $env:SystemDrive -ChildPath ("OSDCloud\Scripts\" + $FileName)
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

function Create-ScriptFolder {
    param (
        [string]$FolderPath
    )
    If (!(Test-Path -Path $FolderPath)) {
        New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
    }
}

# Set script folder paths
$scriptFolderPath = "C:\temp\"

# Create script folder
Create-Folder -FolderPath $scriptFolderPath

#Assign PC to User
Start-Process "$env:SystemDrive\OSDCloud\Scripts\OSDCloud-Assign-User.exe" -ArgumentList "ArgumentsForExecutable" -Wait

# Download ServiceUI.exe
Write-Host -ForegroundColor Gray "Download ServiceUI.exe from GitHub Repo"
Invoke-WebRequest https://github.com/piratesedge/intune/raw/main/ServiceUI64.exe -OutFile "C:\temp\ServiceUI.exe"

#Copy Files from Image to C: Drive
Copy-FromBootImage -FileName "OOBE-Task.exe"
Copy-FromBootImage -FileName "SpecialiseTaskScheduler.ps1"
Copy-FromBootImage -FileName "OOBE-Startup-Script.ps1"
Copy-FromBootImage -FileName "SendKeysSHIFTnF10.ps1"

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
powershell.exe -Command Set-ExecutionPolicy RemoteSigned -Force
powershell.exe -Command Start-Process "C:\temp\SpecialiseTaskScheduler.ps1
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host  -ForegroundColor Green "Restarting in 5 seconds!"
Start-Sleep -Seconds 5
wpeutil reboot
