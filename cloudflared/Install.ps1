# Start if APP is installed but not running, else set DNS to Cloudlflare Plain
function CheckRunningStatus {
    if (Get-Command -Name $Command -ErrorAction SilentlyContinue) {
        if (-not(Get-Process -Name $Command -ErrorAction SilentlyContinue)) {
            FreePort53; ConfigureSystemDNS
            Start-Process "$Application" -ArgumentList "--config-path=$PSScriptRoot\config.yaml" -WindowStyle Minimized
        }
    } else {
        Write-Host 'Setting DNS to [Cloudflare Plain] instead.'
        Get-NetAdapter -Physical | Set-DnsClientServerAddress -ServerAddresses @('1.1.1.1', '1.0.0.1', '2606:4700:4700::1111', '2606:4700:4700::1001')
    }
}

# 
function AfterInstall {
    SetToPath
    # Setup 
    if ($installorupdate -eq 'Install') {
        QuickStart
    } else {
        FreePort53; ConfigureSystemDNS; AutoStart
        if ((Read-Host 'Set Config?(y/n)').ToLower() -eq 'y') {
            CreateConfig
        }
    }
    # Run
    if ((Read-Host "Start $Application?(y/n)").ToLower() -eq 'y') {
        Start-ScheduledTask -TaskName $Command
    }
}

# Use Winget
function WingetInstall {
    Write-Host "$installorupdate using Winget:"
    winget $InstallUpdate $PackageIdentifier

    if ($LASTEXITCODE -in ('-1978335150', '-1978335189')) {
        #  winget install $PackageIdentifier --force # This Works as well but it doesn't overwrite
        winget uninstall $PackageIdentifier
        winget install $PackageIdentifier
    }

    if ($LASTEXITCODE -eq '0') {
        FreePort53
        # Copy Files to Path instead of Creating Links this wil allow seamless Updates.
        $AppLink = "$env:LOCALAPPDATA\Microsoft\WinGet\Links\$Application"
        New-Item -Path $InstallationPath -ItemType Directory -Force | Out-Null
        Copy-Item -Path $((Get-Item (Get-Item -Path $AppLink).Target).DirectoryName) -Destination $InstallationPath -Recurse -Force

        # Remove Link (to run the executable from proper directory)
        Remove-Item $AppLink -Force 
        
        # After Install
        UninstallFile; AfterInstall
    }
}

# Not Being Used
function CheckInternetAccessDNS {
    try {
        $URLTORESOLVE = 'one.one.one.one'
        $DNSResolve = [System.Net.Dns]::GetHostAddresses("$URLTORESOLVE")
        if ($DNSResolve.Length -gt 0) {
            Write-Host "DNS '$URLTOCHECK': Reachable" -ForegroundColor Green
            Write-Host 'Resolved IPs :'
            $DNSResolve.IPAddressToString | Sort-Object
        }
    } catch {
        Write-Host "DNS '$URLTOCHECK': UNREACHABLE" -ForegroundColor Red
    }
}
## 


function CheckInternetAccess {
    $URLTOCHECKConnection = 'github.com'
    if (Test-Connection -ComputerName $URLTOCHECKConnection -BufferSize 2 -Count 1 -ErrorAction SilentlyContinue -Quiet) {
        Write-Host 'Internet access is available.' -ForegroundColor Green
        return $true
    } else {
        Write-Host 'No internet access detected.' -ForegroundColor Red
        return $false
    }
}

function CheckAndInstall {
    CheckRunningStatus
    $internetAccess = CheckInternetAccess
    if ($internetAccess) {

        if ($wingetAvailable) {
            if ((Read-Host "$InstallUpdate using Winget?(y/n)").ToLower() -eq 'y') {
                WingetInstall
            } else {
                $latestjson = Invoke-RestMethod -Uri "https://api.github.com/repos/$apiurl"
                $Windows64 = $latestjson.assets | Where-Object { $_.Name -match "$packagestring" }
                $latestVersion = [version]::Parse([regex]::Matches(($latestjson.tag_name), '\d+\.\d+\.\d+').Value)
                $currentVersion = [Version]($isinstalled.Version)

                if ($?) {
                    if ($currentVersion -eq $latestVersion) {
                        Write-Host "Latest version is installed: $latestVersion"
                    } else {
                        Write-Host "$InstallUpdate $Command : $latestVersion"
                        $downloadPath = "$env:USERPROFILE\Downloads\$($Windows64.name)"
        
                        Start-BitsTransfer -Source $($Windows64.browser_download_url) -Destination $downloadPath
        
                        if ($?) {
                            # Proceed with the rest of the installation logic
                            FreePort53
                            Expand-Archive -Path $downloadPath -DestinationPath $InstallationPath -Force
                            CreateUninstall
                            AfterInstall
                        } else {
                            Write-Host 'Error occurred during BITS transfer.'
                        }
                    }
                } else {
                    Write-Host 'Error occurred during Invoke-RestMethod.'
                }
            }
        }
    } else {
        Write-Host 'Github Unreachable' 
    }
}


function UninstallFile {
    @"
@echo off
setlocal

:: Check if running with admin privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    Write-Output Running with admin privileges.
) else (
    Write-Output Not running with admin privileges. Restarting with admin privileges...
    powershell -Command "Start-Process '%~0' -Verb RunAs"
    exit
)

:: Your script's main code goes here
reg DELETE "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$UninstallKey" /f
taskkill /F /IM "$Application"
rmdir /S /Q "%LOCALAPPDATA%\Programs\$Command"

:: Self-deletion
del "%~f0"

"@ | Out-File -FilePath "$datapath\Uninstall.bat" -Encoding Default -Force
}

function CreateUninstall {
    $registryPath = "HKCU:\$UninstallPath\$UninstallKey"

    # Check if the registry key exists, create it if not
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force -Verbose
    }

    # Remove existing registry values if needed
    $UninstallKey = $isinstalled.TagId
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{$UninstallKey}"

    Remove-ItemProperty -Path $registryPath -Name 'DisplayVersion' -ErrorAction SilentlyContinue -Verbose

    if ($latestVersion) {
        Set-ItemProperty -Path $registryPath -Name 'DisplayVersion' -Value "$latestVersion" -Type String -Verbose
    }
    Set-ItemProperty -Path $registryPath -Name 'UninstallString' -Value "$datapath\Uninstall.bat" -Type String -Verbose
    Set-ItemProperty -Path $registryPath -Name 'DisplayName' -Value "$PackageName" -Type String -Verbose
    Set-ItemProperty -Path $registryPath -Name 'Publisher' -Value "$Publisher" -Type String -Verbose
    Set-ItemProperty -Path $registryPath -Name 'InstallDate' -Value "$dateString" -Type String -Verbose
    Set-ItemProperty -Path $registryPath -Name 'InstallLocation' -Value "$InstallationPath" -Type String -Verbose
    UninstallFile
}


# Uninstall
function Uninstall {
    if ($isinstalled) {
        if ($wingetAvailable) {
            winget uninstall $PackageIdentifier 
        }
        $UninstallKey = $isinstalled.TagId
        Start-Process -FilePath 'msiexec.exe' -ArgumentList "/X{$UninstallKey}" -Wait
        UndoQuickStart
    } else {
        Write-Host 'Not Installed'
    }
}