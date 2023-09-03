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
    New-Item -Path 'C:\Windows\system32\config\systemprofile\.cloudflared\config.yml' -Value "$datapath\config.yml" -ItemType SymbolicLink -Force -Verbose
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
#$currentVersion = [Version]($isinstalled.Version)


foreach ($property in $providers.PSObject.Properties) {
    Set-Variable -Name $property.Name -Value $property.Value
}
function CheckRunningStatus {
    if (Get-Command -Name $Command -ErrorAction SilentlyContinue) {
        $isconnected = CheckInternetAccess
        if ($isconnected -eq $false) { ConfigureSystemDNS; StopApp; FreePort53; Start-Service $Command -Verbose; Start-Sleep 2 }
    }
    $isconnected = CheckInternetAccess
    if ($isconnected -eq $false) {
        Write-Host 'Setting DNS to [Cloudflare Plain] instead.'
        Get-NetAdapter -Physical | Set-DnsClientServerAddress -ServerAddresses @('1.1.1.1', '1.0.0.1', '2606:4700:4700::1111', '2606:4700:4700::1001')
    }
}

function VerfiyUpdate {
    $latestVersion = [version]::Parse([regex]::Matches(($latestjson.tag_name), '\d+\.\d+\.\d+').Value)
    $currentVersion = [version]::Parse([regex]::Matches((& $Application --version), '\d+\.\d+\.\d+').Value)
    if ($latestVersion -eq $currentVersion) {
        $SucessUpdate = $true
        return $SucessUpdate 
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

    # Get-ScheduledTask -TaskName "$Application" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false


}