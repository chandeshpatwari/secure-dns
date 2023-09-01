. "$PSScriptRoot\CreateUpstream.ps1"

function ShowSetupMenu {
    Write-Host '------- DNS Service Setup Menu ----------'
    Write-Host '1. Reset Config'
    Write-Host '2. Remove Config'
    Write-Host '3. Set Config'
    Write-Host '4. Free Port 53'
    Write-Host '5. Configure System DNS'
    Write-Host '6. Setup Auto Start'
    Write-Host '7. Exit'
}

function CheckRunningStatus {
    if (Get-Command -Name $Command -ErrorAction SilentlyContinue) {
        if (!(Get-Process -Name $Command -ErrorAction SilentlyContinue)) {
            FreePort53; ConfigureSystemDNS
            Start-Process "$Application" -ArgumentList 'proxy-dns' -WindowStyle Minimized
        }
    } else {
        Write-Host 'Setting DNS to [Cloudflare Plain] instead.'
        Get-NetAdapter -Physical | Set-DnsClientServerAddress -ServerAddresses @('1.1.1.1', '1.0.0.1', '2606:4700:4700::1111', '2606:4700:4700::1001')
    }
}

function FreePort53 {
    Write-Host 'Stopping process using port 53' -ForegroundColor Green
    $dnsConnections = Get-NetTCPConnection -LocalPort '53' -EA SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
    if ($dnsConnections) {
        Get-Process -Id $dnsConnections -ErrorAction SilentlyContinue | Stop-Process -Verbose -Force
    }
    Get-Process -Name "$Command" -ErrorAction SilentlyContinue | Stop-Process -Force -Verbose
}

function ConfigureSystemDNS {
    Write-Host 'Configuring System DNS to use loopback address' -ForegroundColor Green
    Get-NetAdapter -Physical | Set-DnsClientServerAddress -ResetServerAddresses
    Get-NetAdapter -Physical | Set-DnsClientServerAddress -ServerAddresses @('127.0.0.1', '::1')
}

function FixDOH {
    $fileContent = Get-Content "$datapath\config.yaml"
    $lastTwoLines = $fileContent[-2..-1]

    $condition1 = $lastTwoLines -match 'f'
    $condition2 = $lastTwoLines -match '://'

    if ($condition1 -and $condition2) {
        $fileContent = $fileContent[0..($fileContent.Count - 3)]
        $fileContent | Set-Content "$datapath\config.yaml"
        Write-Host 'Last two lines removed.'
    } else {
        Write-Host 'Conditions not met. Nothing removed.'
    }   
}

function CreateConfig {
    $SetConfig = Read-Host "Press 'e' for DOH Cloudflare. 'c' to configure, or 'e' for edit yourself. Anything else to skip."
    if ($SetConfig -eq 'e') {
        Get-Content "$PSScriptRoot\config.yaml" | Set-Content -Path "$datapath\config.yaml" -Force
    } elseif ($SetConfig -eq 'c') {
        $SelectedConfig = CreateLinks
        $defaultConfig = Get-Content "$PSScriptRoot\config-base.yaml"
        $defaultConfig += $SelectedConfig
        $ShowVerbose = Read-Host 'Show Verbose Logs?(y/n)'
        if ($ShowVerbose -eq 'y') {
            $defaultConfig += 'verbose: true'
        }
        $storelog = Read-Host 'Store Basic Logs?(y/n)'
        if ($storelog -eq 'y') {
            $defaultConfig += "output: $datapath\log.txt"
        }
        $defaultConfig | Set-Content -Path "$datapath\config.yaml" -Force
        FixDOH
    } elseif ($SetConfig -eq 'e') {
        Add-Content '' -Path "$datapath\config.yaml" -Force
        notepad.exe "$datapath\config.yaml"
    } else {
        $null
    }
}
function AutoStart {
    @"
CreateObject("WScript.Shell").Run "$Application --config-path=$datapath\config.yaml", 1, True
"@  | Out-File -FilePath "$datapath\start-service.vbs" -Force
    $taskAction = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument "$datapath\start-service.vbs"
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $taskSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -Priority 1 -AllowStartIfOnBatteries
    Register-ScheduledTask -Action $taskAction -Trigger $trigger -TaskName "$Command" -Settings $taskSettings -Force | Out-Null
    Enable-ScheduledTask -TaskName "$command"
}

function QuickStart {
    FreePort53; ConfigureSystemDNS; CreateConfig; AutoStart
}

function UndoQuickStart {
    Write-Host 'Removing Config'
    Get-ScheduledTask -TaskName "$Application" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false
    Get-NetAdapter -Physical | Set-DnsClientServerAddress -ResetServerAddresses
    Remove-Item -Path "$datapath" -Recurse -Force -Verbose
}

function StartSetup {
    Clear-Host
    do {
        ShowSetupMenu
        $SetupChoice = Read-Host 'Enter your choice'

        switch ($SetupChoice) {
            '1' {
                QuickStart 
            }
            '2' {
                UndoQuickStart 
            }
            '3' {
                CreateConfig                
            }
            '4' {
                FreePort53 
                
            }
            '5' {
                ConfigureSystemDNS 
                
            }
            '6' {
                AutoStart
            }
            '7' {
                return 
            }
            default {
                Write-Host 'Invalid choice. Please select a valid option.' 
            }
        }
        Pause
        Clear-Host
    } while ($SetupChoice -ne '6')
}


