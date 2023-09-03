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

function DownloadAPP {
    param (
        [string]$DownloadMethod,
        [String]$FirstInstall
    )

    if ($DownloadMethod -eq 's') {
        # Self Update
        Write-Host 'Please Wait....'
        Start-Process -FilePath $Application -ArgumentList 'update' -NoNewWindow -Wait
    } elseif ($DownloadMethod -eq 'm') {
        # Download msi
        Write-Host "Downloading $Command : $latestVersion"
        $Windows64 = $latestjson.assets | Where-Object { $_.Name -match "$packagestring" }
        $downloadPath = Join-Path $env:USERPROFILE "Downloads\$($Windows64.name)"
        # Start-BitsTransfer -Source $($Windows64.browser_download_url) -Destination $downloadPath
        if ($?) { StopApp; FreePort53; Start-Process -FilePath $downloadPath -Wait; Start-Service $Command -Verbose -ErrorAction SilentlyContinue }
    }

    if ($FirstInstall -eq 'y') { Write-Host 'First Install'; StartSetup }
}

function CheckAndInstall {
    $internetAccess = CheckInternetAccess; if (!($internetAccess)) { return }
    if ($wingetAvailable) {
        if ((Read-Host "$InstallUpdate using Winget?(y/n)").ToLower() -eq 'y') { WingetInstall; return }
    }

    $latestjson = Invoke-RestMethod -Uri "https://api.github.com/repos/$apiurl"
    $latestVersion = [version]::Parse([regex]::Matches(($latestjson.tag_name), '\d+\.\d+\.\d+').Value)
    if ($currentVersion -eq $latestVersion) {
        Write-Host "Latest version is installed: $latestVersion"
    } else {
        Write-Host "Version installed: $currentVersion "
        Write-Host "$InstallUpdate $Command : $latestVersion"
        if ($currentVersion) {
            $UpdateMethod = Read-Host "Press 'm' to use msi(recommended), 's' to self update."
            if ($UpdateMethod -eq 'm') { DownloadAPP -DownloadMethod 'm' } elseif ($UpdateMethod -eq 's') { DownloadAPP -DownloadMethod 's' }
        } else {
            DownloadAPP -DownloadMethod 'm' -FirstInstall y
        }
    }
}

# Uninstall
function Uninstall {
    if ($isinstalled) {
        if ((Read-Host 'Are you sure?(y/n)').ToLower() -eq 'y') {
            if ($wingetAvailable) { winget uninstall $PackageIdentifier } else { Start-Process -FilePath 'msiexec.exe' -ArgumentList "/X{$($isinstalled.TagId)}" -Wait }
            UndoQuickStart
        }
    } else {
        Write-Host 'Not Installed'
    }
}
