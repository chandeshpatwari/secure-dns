$providers = Get-Content "$PSScriptRoot\transformed_providers.json" | ConvertFrom-Json
function CreateLinks {
    do {
        $i = 0
        $ProviderNames = foreach ($providerName in $providers.PSObject.Properties.Name) {
            "$i : $providerName"
            $i++
        }

        Clear-Host
        Write-Host 'DNS Provider Selection Menu:'
        $ProviderNames | ForEach-Object { Write-Host "  $_" }
        $selectedIndex = Read-Host 'Select DNS provider'

        if ($selectedIndex -eq '') {
            $null
        } elseif ($selectedIndex -as [int] -ge 0 -and $selectedIndex -as [int] -lt $providers.PSObject.Properties.Name.Count) {
            $selectedProviderName = $providers.PSObject.Properties.Name[$selectedIndex]
            $selectedProviderInfo = $providers.$selectedProviderName
            Write-Host "Selected $selectedProviderName" -ForegroundColor Green
            $SelectedConfig = $selectedProviderInfo | ForEach-Object { "https://$_/dns-query" }
            return $SelectedConfig
        }
    } while (-not $SelectedConfig)
}

$SelectedConfig = CreateLinks
$SelectedConfig