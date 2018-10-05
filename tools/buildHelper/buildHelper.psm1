# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Gets the Current version of PowerShell from the PowerShell repo
function Get-PowerShellVersion
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [Parameter(ParameterSetName='Preview', HelpMessage="Gets the preview version.  Without this it gets the current stable version.")]
        [switch] $Preview,
        [Parameter(ParameterSetName='Servicing', HelpMessage="Gets the servicing version.  Without this it gets the current stable version.")]
        [switch] $Servicing,
        [Parameter(HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [switch] $Linux
    )

    $metaData = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json'

    $releaseTag = if ($Preview.IsPresent) {
        $metaData.PreviewReleaseTag
    } elseif ($Servicing.IsPresent) {
        $metaData.ServicingReleaseTag
    }else {
        $metaData.StableReleaseTag
    }

    $version = $releaseTag -replace '^v', ''

    if ($Linux.IsPresent) {
        $version = $version -replace '\-', '~'
    }
    
    return $version
}

# Gets list of images names
function Get-ImageList
{
    param(
        [Parameter(HelpMessage="Filters returned list to stable or preview images.  Default to all images.")]
        [ValidateSet('stable','preview','servicing','all')]
        [string]
        $Channel='all'
    )

    # Get the names of the builds.
    $releasePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\release'
    $stablePath = Join-Path -Path $releasePath -ChildPath 'stable'
    $previewPath = Join-Path -Path $releasePath -ChildPath 'preview'
    $servicingPath = Join-Path -Path $releasePath -ChildPath 'servicing'

    if ($Channel -in 'stable', 'all')
    {
        Get-ChildItem -Path $stablePath -Directory | Select-Object -ExpandProperty Name | Write-Output
    }

    if ($Channel -in 'servicing', 'all')
    {
        Get-ChildItem -Path $stablePath -Directory | Select-Object -ExpandProperty Name | Write-Output
    }

    if ($Channel -in 'preview', 'all')
    {
        Get-ChildItem -Path $previewPath -Directory | Select-Object -ExpandProperty Name | Where-Object { $dockerFileNames -notcontains $_ } | Write-Output
    }
}

class DockerImageMetaData {
    [Bool]
    $IsLinux = $false

    [System.Nullable[Bool]]
    $UseLinuxVersion = $null

    [bool] ShouldUseLinuxVersion() {
        if($this.UseLinuxVersion -is [bool])
        {
            return $this.UseLinuxVersion
        }

        return $this.IsLinux
    }

    [string]
    $PackageFormat = "undefined"
}

Function Get-DockerImageMetaData
{
    param(
        [parameter(Mandatory)]
        $Path
    )

    if (Test-Path $Path)
    {
        $meta = Get-Content -Path $Path | ConvertFrom-Json
        return [DockerImageMetaData] $meta
    }
    
    return [DockerImageMetaData]::new()
}
