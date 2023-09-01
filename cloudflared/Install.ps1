
function AfterInstall {
    if ($installorupdate -eq 'Install') {
        QuickStart
    } else {
        FreePort53; ConfigureSystemDNS; AutoStart
        if ((Read-Host 'Set Config?(y/n)').ToLower() -eq 'y') {
            CreateConfig
        }
    }
    # Run
    cloudflared.exe service install
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
}

# 

function UpdateVersion {
    $registryPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{$UninstallKey}"
    if (!(Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force -Verbose
    }

    $latestVersion = [version]::Parse([regex]::Matches((& $Application --version), '\d+\.\d+\.\d+').Value)
    if ($latestVersion) {
        Set-ItemProperty -Path $registryPath -Name 'DisplayVersion' -Value "$latestVersion" -Type String -Verbose
    }    
}
# Update/Install
function UpdateProgram {
    param (
        [string]$UpdateMethod
    )

    if ($UpdateMethod -eq 'a') {
        $UpdateMethod = Read-Host "Press 'g' to use GitHub (Small Download Size), 's' to Self Update"
    }

    if ($UpdateMethod -eq 'g') {
        $Windows64 = $latestjson.assets | Where-Object { $_.Name -match "$packagestring" }
        $downloadPath = Join-Path $env:USERPROFILE "Downloads\$($Windows64.name)"
        Start-BitsTransfer -Source $($Windows64.browser_download_url) -Destination $downloadPath
        if ($?) {
            & $downloadPath
        } else {
            Write-Host 'Unsucessful Download'
        }     
        return $?  # Return the exit code of Start-Process
    } elseif ($UpdateMethod -eq 's') {

        Write-Host 'Please Wait....'
        & $Application update; if ($LASTEXITCODE -eq '0') {
            UpdateVersion
            Write-Output 'hi'
            return $?
        }
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
    $internetAccess = CheckInternetAccess
    if ($internetAccess) {
        if ($wingetAvailable) {
            if ((Read-Host "$InstallUpdate using Winget?(y/n)").ToLower() -eq 'y') {
                WingetInstall
            } else {
                #$currentVersion = [Version]($isinstalled.Version)
                if ($isinstalled) {
                    $currentVersion = [version]::Parse([regex]::Matches((& $Application --version), '\d+\.\d+\.\d+').Value)
                }
                $latestjson = Invoke-RestMethod -Uri "https://api.github.com/repos/$apiurl"
                $latestVersion = [version]::Parse([regex]::Matches(($latestjson.tag_name), '\d+\.\d+\.\d+').Value)
                if ($?) {
                    if ($currentVersion -eq $latestVersion) {
                        Write-Host "Latest version is installed: $latestVersion"
                    } else {
                        Write-Host "$InstallUpdate $Command : $latestVersion"
                        if ($InstallUpdate -eq 'Update') {
                            $Updateresult = UpdateProgram -UpdateMethod 'a'
                        } else {
                            $Updateresult = UpdateProgram -UpdateMethod 'g'
                        }
                        if ($Updateresult -eq $True) {
                            Write-Host 'Latest Version Installed.'
                            
                        } else {
                            Write-Host 'Error occurred during Installation.'
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


# Uninstall
function Uninstall {
    if ($isinstalled) {
        if ($wingetAvailable) {
            winget uninstall $PackageIdentifier 
        } else {
            Start-Process -FilePath 'msiexec.exe' -ArgumentList "/X{$UninstallKey}" -Wait
        }
        UndoQuickStart
    } else {
        Write-Host 'Not Installed'
    }
}
