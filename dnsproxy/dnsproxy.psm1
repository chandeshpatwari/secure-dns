# Package Data
$PackageData = @'
Command,Application,PackageName,PackageIdentifier,Publisher
dnsproxy,dnsproxy.exe,DNS Proxy,AdGuard.dnsproxy,AdGuard
'@ | ConvertFrom-Csv

# Github Repo URL
$apiurl = 'AdguardTeam/dnsproxy/releases/latest'
$packagestring = 'windows-amd64'

# Paths
$path = 'windows-amd64'

Export-ModuleMember -Variable PackageData, apiurl, packagestring, path, upstreamprefix
