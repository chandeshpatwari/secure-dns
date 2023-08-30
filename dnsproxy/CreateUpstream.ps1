$providers = Get-Content "$PSScriptRoot\providers.json" | ConvertFrom-Json

$ProtocolTable = @'
Unencrypted,,,
DOH,https://,/dns-query
DOH[forced http3],h3://,/dns-query
DOT,tls://,
QUIC,quic://,
Unencrypted UDP,upd://,
Unencrypted TCP,tcp://,
'@ | ConvertFrom-Csv -Header Protocol, Prefix, Suffix

$ProtocolNames = @($ProtocolTable.Protocol)
$ProviderNames = @($providers.Provider)

function CreateLinks {
    do {
        Clear-Host
        
        $i = 0
        Write-Host 'Select DNS Provider:'
        $ProviderNames | ForEach-Object {
            Write-Host "$i. $_"
            $i++
        }

        $selectedIndex = Read-Host 'Select DNS provider'

        if ($selectedIndex -eq '') {
            Write-Host 'Exiting the script.'
            break
        } elseif ([int]$selectedIndex -ge 0 -and [int]$selectedIndex -lt $ProviderNames.Count) {
            $ProviderName = $providers[$selectedIndex].Provider
            $SelectedAddress = $providers[$selectedIndex].Address

            do {
                
                $i = 0
                Write-Host 'Select Protocol(Supported Protocol are metioned beside the Provders)'
                $ProtocolNames | ForEach-Object {
                    Write-Host "$i. $_"
                    $i++
                }

                $ProtocolIndex = Read-Host 'Select Protocol'

                if ($ProtocolIndex -eq '') {
                    Write-Host 'Exiting the script.'
                    break
                } elseif ([int]$ProtocolIndex -in (0..($ProtocolNames.Count - 1))) {
                    $ProtocolPrefix = $ProtocolTable[$ProtocolIndex].Prefix
                    $protocol = $ProtocolTable[$ProtocolIndex].Protocol
                    $ProtocolTableuffix = $ProtocolTable[$ProtocolIndex].Suffix
                    $SelectedConfig = $SelectedAddress | ForEach-Object { 
                        '  - ' + "$ProtocolPrefix" + $_ + "$ProtocolTableuffix"
                    }
                }

            } while (-not $SelectedConfig)

            Write-Host "Selected DNS Configuration for $ProviderName using '$protocol':"
            return $SelectedConfig
        } else {
            Write-Host 'Invalid provider index. Please select a valid index or press Enter to exit.'
        }
    } while (-not $SelectedConfig)      
}