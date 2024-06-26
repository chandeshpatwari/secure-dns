. "$PSScriptRoot\DNSConfig.ps1"
. "$PSScriptRoot\Install.ps1"
. "$PSScriptRoot\SetPath.ps1"

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
        Write-Host 'Loading...'
        $isinstalled = Get-Package -Name "$PackageName" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        Clear-Host
        
        # Uninstall Reg.
        $UninstallPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        $UninstallKey = (Get-ChildItem "HKCU:\$UninstallPath" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$PackageIdentifier*" }).PSChildName
        if (!($UninstallKey)) {
            $UninstallKey = "$PackageIdentifier"
        }
        
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