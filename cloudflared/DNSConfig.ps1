. "$PSScriptRoot\CreateUpstream.ps1"

function SetupMenu {
    Write-Host '------- DNS Service Setup Menu ----------'
    Write-Host '1. Configure [3-6]'
    Write-Host '2. Create/Edit config.yml'
    Write-Host '3. Stop Process using port 53'
    Write-Host '4. Configure System to use loopback address for DNS'
    Write-Host '5. Set Service [Requires Restart]'
    Write-Host '----------------'
    Write-Host '6. UNDO DNS Service Setup'
    Write-Host '7. <-- Back'
}

function CreateConfig {
    $SetConfig = Read-Host "Press 'e' for DOH Cloudflare. 'c' to configure, or 'e' for edit yourself. Anything else to skip."
    if ($SetConfig -eq 'e') {
        Get-Content "$PSScriptRoot\config.yaml" | Set-Content -Path "$datapath\config.yml" -Force
    } elseif ($SetConfig -eq 'c') {
        $configContent = Get-Content "$PSScriptRoot\config.yaml"
        $configContent += 'proxy-dns-upstream:'
        $configContent += CreateLinks
        $lastTwoLines = $configContent | Select-Object -Last 2
        if ($lastTwoLines -match 'f' -and $lastTwoLines -match 'https://') {
            $configContent = $configContent | Select-Object -SkipLast 2
        }
        if ((Read-Host 'Store Basic Logs?(y/n)') -eq 'y') { $configContent += "logDirectory:: $datapath" }
        $configContent | Set-Content -Path "$datapath\config.yml" -Force
    } elseif ($SetConfig -eq 'e') {
        Add-Content '' -Path "$datapath\config.yml" -Force
        notepad.exe "$datapath\config.yml"
    } else {
        $null
    }
}

function FreePort53 {
    Write-Host 'Stopping process using port 53' -ForegroundColor Green
    Get-Process -Name "$Command" -ErrorAction SilentlyContinue | Stop-Process -Force -Verbose
    $dnsConnections = Get-NetTCPConnection -LocalPort '53' -EA SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
    if ($dnsConnections) {
        $Service53 = Get-CimInstance -ClassName Win32_Service | Where-Object { $_.ProcessId -eq $dnsConnections }
        Get-Service $Service53.Name -Verbose | Set-Service -StartupType Manual -Status Stopped
        Get-Process -Id $dnsConnections -ErrorAction SilentlyContinue | Stop-Process -Verbose -Force
    }
}

function ConfigureSystemDNS {
    Write-Host 'Configuring System DNS to use loopback address' -ForegroundColor Green
    Get-NetAdapter -Physical | Set-DnsClientServerAddress -ResetServerAddresses
    Get-NetAdapter -Physical | Set-DnsClientServerAddress -ServerAddresses @('127.0.0.1', '::1')
}

function SetService {
    New-Item -Path $ServiceFilePath -ItemType Directory -Force -ErrorAction SilentlyContinue -Verbose
    New-Item -Path "$ServiceFilePath\config.yml" -ItemType SymbolicLink -Value "$datapath\config.yml" -Force -Verbose
    if ($isinstalled) { & $Application service install; Get-Service $Command }
}

function QuickSetup { CreateConfig; FreePort53; ConfigureSystemDNS; SetService; ipconfig /flushdns }

# Undo 
function UndoSetupMenu {
    Write-Host '------- UNDO DNS Service Setup ----------'
    Write-Host '1. Undo Configure [2,3,4]'
    Write-Host '2. Configure System DNS to Default [3-6]'
    Write-Host '3. Remove Service [Requires Restart]'
    Write-Host '4. Remove config.yml'
    Write-Host '5. <-- Back'
}

function UndoConfigureSystemDNS { Get-NetAdapter -Physical | Set-DnsClientServerAddress -ResetServerAddresses -Verbose }
function UndoSetService { 
    StopApp; & $Application service uninstall 
    cmd /c sc delete $Command
    Remove-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\Cloudflared' -Recurse -Force -ErrorAction SilentlyContinue
    Get-EventLog -List | ForEach-Object { Clear-EventLog -LogName $_.Log }
}
function UndoCreateConfig { ("$ServiceFilePath", "$datapath\config.yml") | ForEach-Object { Remove-Item -Path $_ -Recurse -Force -Verbose } }
function UndoQuickStart { UndoConfigureSystemDNS; UndoSetService; UndoCreateConfig; ipconfig /flushdns }
function UndoSetup {
    Clear-Host
    do {
        UndoSetupMenu
        $UndoSetupChoice = Read-Host 'Enter your choice'

        switch ($UndoSetupChoice) {
            '1' { UndoQuickStart }
            '2' { UndoConfigureSystemDNS }
            '3' { UndoSetService }
            '4' { UndoCreateConfig }
            '5' { return }
            default {
                Write-Host 'Invalid choice. Please select a valid option.' 
            }
        }
        Pause
        Clear-Host
    } while ($SetupChoice -ne '5')
}
## End Undo

function StartSetup {
    Clear-Host
    do {
        SetupMenu
        $SetupChoice = Read-Host 'Enter your choice'

        switch ($SetupChoice) {
            '1' { QuickSetup }
            '2' { CreateConfig }
            '3' { FreePort53 }
            '4' { ConfigureSystemDNS }
            '5' { SetService }
            '6' { UndoSetup }
            '7' { return }
            default {
                Write-Host 'Invalid choice. Please select a valid option.' 
            }
        }
        Pause
        Clear-Host
    } while ($SetupChoice -ne '7')
}