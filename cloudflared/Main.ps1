. "$PSScriptRoot\DNSConfig.ps1"
. "$PSScriptRoot\Install.ps1"
# . "$PSScriptRoot\SetPath.ps1"

function SetUI {
    $Host.UI.RawUI.BackgroundColor = 'Black'
    $Host.UI.RawUI.ForegroundColor = 'White'
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(100, 30)
    Clear-Host
}

function ShowMenu {
    Write-Host '----- Install DNS Service ------'
    Write-Host "1. $InstallUpdate $Command"
    Write-Host "2. $StartStop $Command"
    Write-Host "3. Uninstall $Command"
    Write-Host '4. Setup'
    Write-Host '5. Exit'
}

function StopApp {
    if (Get-Service $Command) { Stop-Service $Command -Verbose -Force -NoWait }
    Stop-Process -Name $Command -ErrorAction SilentlyContinue -Force
}

function StartApp {
    StopApp
    if (Get-Service $Command) { Start-Service $Command -Verbose; Get-Service $Command -Verbose | Set-Service -StartupType Automatic -Status Running } else { Start-Process $Command -ArgumentList 'proxy-dns' -Verbose }
}

function RestartApp {
    if (Get-Service $Command) { Get-Service $Command | Restart-Service -Verbose -Force | Set-Service -StartupType Automatic -Status Running } else { Start-Process $Command -ArgumentList 'proxy-dns' -Verbose }  
}

function Main {
    do {
        Clear-Host
        SetUI
        $isinstalled = Get-Package -Name $PackageName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        $currentVersion = if ($isinstalled) { [version]::Parse([regex]::Matches((& $Application --version), '\d+\.\d+\.\d+').Value) }
        
        $InstallUpdate = if ($isinstalled) { 'Update' } else { 'Install' }

        if (Get-Process -Name $Command -ErrorAction SilentlyContinue) {
            $StartStop = 'Stop'
            $StartStopcmd = 'StopApp'
        } else {
            $StartStop = 'Start'
            $StartStopcmd = 'StartApp'
        }

        Write-Host 'Loading...'
        Clear-Host

        ShowMenu
        $MainChoice = Read-Host 'Enter your choice'

        switch ($MainChoice) {
            '1' { CheckAndInstall }
            '2' { if ($isinstalled) { Invoke-Expression $StartStopcmd } else { Write-Host 'Not Installed' } }
            '3' { Uninstall }
            '4' { StartSetup }
            '5' { exit }
            default { Write-Host 'Invalid choice. Please select a valid option.' }
        }
        Pause
        Clear-Host
    } while ($MainChoice -ne '5')
}