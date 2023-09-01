. "$PSScriptRoot\DNSConfig.ps1"
. "$PSScriptRoot\Install.ps1"
. "$PSScriptRoot\SetPath.ps1"

function CheckRunningStatus {
    if (Get-Command -Name $Command -ErrorAction SilentlyContinue) {
        if (!(Get-Process -Name $Command -ErrorAction SilentlyContinue)) {
            FreePort53; ConfigureSystemDNS
            if ((Get-Service -Name $Application).Status -ne 'Running') {
                Get-Service -Name $Application | Start-Service -Verbose
            } else {
                Start-Process "$Application" -ArgumentList 'proxy-dns' -WindowStyle Hidden
            }
            
        }
    } else {
        Write-Host 'Setting DNS to [Cloudflare Plain] instead.'
        Get-NetAdapter -Physical | Set-DnsClientServerAddress -ServerAddresses @('1.1.1.1', '1.0.0.1', '2606:4700:4700::1111', '2606:4700:4700::1001')
    }
}

function SetUI {
    $Host.UI.RawUI.BackgroundColor = 'Black'
    $Host.UI.RawUI.ForegroundColor = 'White'
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(100, 30)
    Clear-Host
}
function Start-App {
    QuickStart
    Start-ScheduledTask -TaskName $Command
}

function Stop-App {
    Get-Process -Name $Command -ErrorAction SilentlyContinue | Stop-Process -Force -Verbose
}

function ShowMenu {
    Write-Host '------- Install DNS Service ----------'
    Write-Host "1. $InstallUpdate $Command"
    Write-Host "2. $StartStop $Command"
    Write-Host "3. Uninstall $Command"
    Write-Host '4. Adv. Setup'
    Write-Host '5. Exit'
}

function Main {
    do {
        SetUI
        CheckRunningStatus
        Write-Host 'Loading...'
        $isinstalled = Get-Package -Name "$PackageName" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        $UninstallKey = $isinstalled.TagId

        Clear-Host
        

        # Determine whether to start or stop the app
        if (Get-Process -Name $Command -ErrorAction SilentlyContinue) {
            $StartStop = 'Stop'; $StartStopCommand = 'Stop-App'
        } else {
            $StartStop = 'Start'; $StartStopCommand = 'Start-App'
        }

        # Install/Update
        $InstallUpdate = if ($isinstalled) {
            'Update'
        } else {
            'Install'
        }

        ShowMenu
        $MainChoice = Read-Host 'Enter your choice'

        switch ($MainChoice) {
            '1' {
                CheckAndInstall
            }
            '2' {
                if ($isinstalled) {
                    Invoke-Expression $StartStopCommand
                } else {
                    Write-Host 'Not Installed'
                }
            }
            '3' {
                Uninstall
            }
            '4' {
                StartSetup
            }
            '5' {
                exit
            }
            default {
                Write-Host 'Invalid choice. Please select a valid option.'
            }
        }
        Pause
        Clear-Host
    } while ($MainChoice -ne '5')
}