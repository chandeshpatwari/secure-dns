if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Not running with admin privileges. Restarting with admin privileges...'
    Start-Process -FilePath powershell.exe -WindowStyle Normal -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -Wait; Exit
}

# Check For Winget 
$wingetAvailable = Get-Command winget.exe -ErrorAction SilentlyContinue

# Import Package Data
# $PackageData = Get-Content "$PWD\cloudflared.json" | ConvertFrom-Json
$PackageData = Get-Content "$PSScriptRoot\cloudflared.json" | ConvertFrom-Json

# Loop through properties in the JSON object and assign them to variables
foreach ($property in $PackageData.PSObject.Properties) {
    Set-Variable -Name $property.Name -Value $property.Value
}

# Paths
$datapath = "$env:USERPROFILE\.$Command"
$InstallationPath = "$env:LOCALAPPDATA\Programs\$Command"
$binarypath = "$InstallationPath\$path"
$ServiceFilePath = "$env:SYSTEMROOT\system32\config\systemprofile\.$Command"

# Date
$dateString = (Get-Date).ToString('yyyyMMdd')


# Create Data Path
if (!(Test-Path $datapath)) {
    New-Item -Path $datapath -ItemType Directory -Force | Out-Null
}

# Import the module & Call the Start-Setup function
. "$PSScriptRoot\main.ps1"
Main