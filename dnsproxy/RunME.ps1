if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Not running with admin privileges. Restarting with admin privileges...'
    Start-Process -FilePath powershell.exe -WindowStyle Normal -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -Wait; Exit
}


# Check For Winget 
$wingetAvailable = Get-Command winget.exe -ErrorAction SilentlyContinue

# Import Package Data
Import-Module -Name "$PSScriptRoot\dnsproxy.psm1" -Force

# Get Application Details
$Application = $PackageData.Application
$Command = $PackageData.Command
$PackageName = $PackageData.PackageName
$PackageIdentifier = $PackageData.PackageIdentifier
$Publisher = $PackageData.Publisher

# Paths
$datapath = "$env:USERPROFILE\.$Command"
$InstallationPath = "$env:LOCALAPPDATA\Programs\$Command"
$binarypath = "$InstallationPath\$path"

# Create Data Path
if (!(Test-Path $datapath)) {
    New-Item -Path $datapath -ItemType Directory -Force
}

# Date
$dateString = (Get-Date).ToString('yyyyMMdd')

# Import the module & Call the Start-Setup function
. "$PSScriptRoot\main.ps1"
Pause
Main