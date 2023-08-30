function SetToPath {
    Write-Output 'SetPath'
    $CurrentUserPath = ([Environment]::GetEnvironmentVariable('Path', 'User') -replace ';;+', ';').TrimEnd(';')
    $CurrentPath = ([Environment]::GetEnvironmentVariable('Path') -replace ';;+', ';').TrimEnd(';')

    if (Test-Path $binarypath ) {
        if ($CurrentPath.Split(';') -contains $binarypath) {
            Write-Host "The path '$binarypath' is already in the user path variable"
        } else {
            $NewUserPath = "$CurrentUserPath;$binarypath;"
            [Environment]::SetEnvironmentVariable('PATH', $NewUserPath, 'User')
            $env:Path = "$binarypath;$env:Path"
            Write-Host "The path '$binarypath' has been added to the user path variable."
        }
    } else {
        Write-Host 'Path Does Not Exist.'
    }
}

function RemovePath {
    $CurrentUserPath = ([Environment]::GetEnvironmentVariable('Path', 'User') -replace ';;+', ';').TrimEnd(';')

    if ($CurrentUserPath.Split(';') -contains $binarypath) {
        $NewUserPath = ($CurrentUserPath.Replace($binarypath, '')) -replace ';;+', ';'
        [Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')
        $env:Path = "$NewUserPath"
        # rundll32 sysdm.cpl, EditEnvironmentVariables
    } else {
        Write-Host 'Path Variable Does Not Exist.'
    }
}