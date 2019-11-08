[CmdletBinding()]

param(
    [switch]
    $Force
)

Begin
{
    Write-Verbose "Starting..." -Verbose
}

End
{
    $releasePath = Join-Path -Path $PSScriptRoot -ChildPath 'release'
    $path = Join-Path -Path $PSScriptRoot -ChildPath 'templates'
    $exists = [System.IO.File]::Exists($path)
    $do = !$exists -or $Force.isPresent
    $imageNames = Get-ChildItem -Path $path -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName

    if(!$do)
    {
        Write-Warning "Failed to run build structure generation because the generated files exist!"
    }
    else
    {
        for($k in $imageNames | Where-Object { $k -ne "" })
        {
            $imageFolder = New-Item -Path $releasePath -Name $k -ItemType "directory"
            $dockerFolder = New-Item -path $imageFolder -Name "docker" -ItemType "directory"
            New-Item -Path $dockerFolder -Name "Dockerfile" -ItemType "file"
        }
    }
}
