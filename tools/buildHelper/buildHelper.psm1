# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Gets the Current version of PowerShell from the PowerShell repo
# or formats the version based on the parameters
function Get-PowerShellVersion
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [Parameter(Mandatory, ParameterSetName="ExplicitVersionPreview", HelpMessage="Gets the preview version.  Without this it gets the current stable version.")]
        [Parameter(Mandatory, ParameterSetName='Preview', HelpMessage="Gets the preview version.  Without this it gets the current stable version.")]
        [switch] $Preview,

        [Parameter(Mandatory, ParameterSetName="ExplicitVersionServicing", HelpMessage="Gets the preview version.  Without this it gets the current stable version.")]
        [Parameter(Mandatory, ParameterSetName='Servicing', HelpMessage="Gets the servicing version.  Without this it gets the current stable version.")]
        [switch] $Servicing,

        [Parameter(ParameterSetName="LookupVersion",HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [Parameter(ParameterSetName="ExplicitVersion",HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [Parameter(ParameterSetName="ExplicitVersionPreview",HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [Parameter(ParameterSetName="ExplicitVersionServicing",HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [Parameter(ParameterSetName='Servicing', HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [Parameter(ParameterSetName='Preview', HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [switch] $Linux,

        [Parameter(Mandatory,ParameterSetName="ExplicitVersion", HelpMessage="Don't lookup version, just transform this standardized version based on the other parameters.")]
        [Parameter(Mandatory,ParameterSetName="ExplicitVersionServicing", HelpMessage="Don't lookup version, just transform this standardized version based on the other parameters.")]
        [Parameter(Mandatory,ParameterSetName="ExplicitVersionPreview", HelpMessage="Don't lookup version, just transform this standardized version based on the other parameters.")]
        [ValidatePattern('(\d+\.){2}\d(-\w+(\.\d+)?)?')]
        [string]
        $Version
    )

    if ($PSCmdlet.ParameterSetName -notlike 'ExplicitVersion*') {
        $metaData = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json'

        $releaseTag = if ($Preview.IsPresent) {
            $metaData.PreviewReleaseTag
        }
        elseif ($Servicing.IsPresent) {
            $metaData.ServicingReleaseTag
        }
        else {
            $metaData.StableReleaseTag
        }

        $retVersion = $releaseTag -replace '^v', ''
    }
    else {
        $retVersion = $Version
    }

    if ($Linux.IsPresent) {
        $retVersion = $retVersion -replace '\-', '~'
    }

    return $retVersion
}

# Gets list of images names
function Get-ImageList
{
    param(
        [Parameter(HelpMessage="Filters returned list to stable or preview images.  Default to all images.")]
        [ValidateSet('stable','preview','servicing','all','community-stable','community-preview','community-servicing')]
        [string[]]
        $Channel='all'
    )

    # Get the names of the builds.
    $releasePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\release'
    $stablePath = Join-Path -Path $releasePath -ChildPath 'stable'
    $previewPath = Join-Path -Path $releasePath -ChildPath 'preview'
    $servicingPath = Join-Path -Path $releasePath -ChildPath 'servicing'
    $communityStablePath = Join-Path -Path $releasePath -ChildPath 'community-stable'
    $communityPreviewPath = Join-Path -Path $releasePath -ChildPath 'community-preview'
    $communityServicingPath = Join-Path -Path $releasePath -ChildPath 'community-ervicing'

    if ($Channel -in 'stable', 'all')
    {
        Get-ChildItem -Path $stablePath -Directory | Select-Object -ExpandProperty Name | Write-Output
    }

    if ($Channel -in 'servicing', 'all')
    {
        Get-ChildItem -Path $servicingPath -Directory | Select-Object -ExpandProperty Name | Write-Output
    }

    if ($Channel -in 'preview', 'all')
    {
        Get-ChildItem -Path $previewPath -Directory | Select-Object -ExpandProperty Name | Where-Object { $dockerFileNames -notcontains $_ } | Write-Output
    }

    if ($Channel -in 'community-stable', 'all')
    {
        Get-ChildItem -Path $communityStablePath -Directory | Select-Object -ExpandProperty Name | Write-Output
    }

    if ($Channel -in 'community-servicing', 'all')
    {
        Get-ChildItem -Path $communityServicingPath -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name | Write-Output
    }

    if ($Channel -in 'community-preview', 'all')
    {
        Get-ChildItem -Path $communityPreviewPath -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name | Where-Object { $dockerFileNames -notcontains $_ } | Write-Output
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

    [bool]
    $SkipWebCmdletTests = $false

    [bool]
    $SkipGssNtlmSspTests = $false

    [bool]
    $Base64EncodePackageUrl = $false

    [string]
    $OsVersion

    [string]
    $TagGroup = 'Linux'

    [ShortTagMetaData[]]
    $ShortTags

    [string[]]
    $tagTemplates
}

class ShortTagMetaData {
    [string] $Tag
    [Bool] $KnownIssue
}

Function Get-DockerImageMetaData
{
    param(
        [parameter(Mandatory)]
        $Path
    )

    if (Test-Path $Path)
    {
        try {
            $meta = Get-Content -Path $Path | ConvertFrom-Json
            return [DockerImageMetaData] $meta
        }
        catch {
            throw "$_ converting $Path"
        }
    }

    return [DockerImageMetaData]::new()
}

# this function wraps native command Execution
# for more information, read https://mnaoumov.wordpress.com/2015/01/11/execution-of-external-commands-in-powershell-done-right/
function script:Start-NativeExecution
{
    param(
        [scriptblock]$sb,
        [switch]$IgnoreExitcode,
        [switch]$VerboseOutputOnError
    )
    $backupEAP = $script:ErrorActionPreference
    $script:ErrorActionPreference = "Continue"
    try {
        if($VerboseOutputOnError.IsPresent)
        {
            $output = & $sb 2>&1
        }
        else
        {
            & $sb
        }

        # note, if $sb doesn't have a native invocation, $LASTEXITCODE will
        # point to the obsolete value
        if ($LASTEXITCODE -ne 0 -and -not $IgnoreExitcode) {
            if($VerboseOutputOnError.IsPresent -and $output)
            {
                $output | Out-String | Write-Verbose -Verbose
            }

            # Get caller location for easier debugging
            $caller = Get-PSCallStack -ErrorAction SilentlyContinue
            if($caller)
            {
                $callerLocationParts = $caller[1].Location -split ":\s*line\s*"
                $callerFile = $callerLocationParts[0]
                $callerLine = $callerLocationParts[1]

                $errorMessage = "Execution of {$sb} by ${callerFile}: line $callerLine failed with exit code $LASTEXITCODE"
                throw $errorMessage
            }
            throw "Execution of {$sb} failed with exit code $LASTEXITCODE"
        }
    } finally {
        try {
            $script:ErrorActionPreference = $backupEAP
        }
        catch {
        }
    }
}

# Add a parameter attribute to an Attribute Collection
function Add-ParameterAttribute {
    param(
        [Parameter(Mandatory)]
        [object]
        $Attributes,
        [Parameter(Mandatory)]
        [string]
        $ParameterSetName
    )
    $ParameterAttr = New-Object "System.Management.Automation.ParameterAttribute"
    $ParameterAttr.ParameterSetName = $ParameterSetName
    $ParameterAttr.Mandatory = $true
    $Attributes.Add($ParameterAttr) > $null
}

function Get-Versions
{
    param(
        [Parameter(Mandatory)]
        [String]
        $Channel,

        [string]
        $ServicingVersion,

        [string]
        $PreviewVersion,

        [string]
        $StableVersion
    )

    Write-Verbose "Getting Version for $Channel - servicing: $ServicingVersion; Preview: $PreviewVersion; stable: $stableVersion"

    $versionExtraParams = @{}

    switch -RegEx ($Channel)
    {
        'servicing$' {
            if($ServicingVersion){
                $versionExtraParams['Version'] = $ServicingVersion
            }

            $windowsVersion = Get-PowerShellVersion -Servicing @versionExtraParams
            $linuxVersion = Get-PowerShellVersion -Linux -Servicing @versionExtraParams
        }
        'preview$' {
            if($PreviewVersion){
                $versionExtraParams['Version'] = $PreviewVersion
            }

            $windowsVersion = Get-PowerShellVersion -Preview @versionExtraParams
            $linuxVersion = Get-PowerShellVersion -Linux -Preview @versionExtraParams
        }
        'stable$' {
            if($StableVersion){
                $versionExtraParams['Version'] = $StableVersion
            }

            $windowsVersion = Get-PowerShellVersion @versionExtraParams
            $linuxVersion = Get-PowerShellVersion -Linux @versionExtraParams
        }
        default {
            throw "unknown channel: $Channel"
        }
    }

    return [PSCustomObject] @{
        WindowsVersion = $windowsVersion
        LinuxVersion = $linuxVersion
    }
}

# Get the meta data and the tag data for an image
function Get-DockerImageMetaDataWrapper
{
    param(
        [parameter(Mandatory)]
        [string]
        $DockerFileName,

        [switch]
        $CI,

        [switch]
        $IncludeKnownIssues,

        [string]
        $TagFilter,

        [parameter(Mandatory)]
        [string]
        $ChannelPath
    )

    $imagePath = Join-Path -Path $ChannelPath -ChildPath $dockerFileName
    $scriptPath = Join-Path -Path $imagePath -ChildPath 'getLatestTag.ps1'
    $tagsJsonPath = Join-Path -Path $imagePath -ChildPath 'tags.json'
    $metaJsonPath = Join-Path -Path $imagePath -ChildPath 'meta.json'

    # skip an image if it doesn't exist
    if(!(Test-Path $scriptPath))
    {
        $message = "Channel: $actualChannel, Name: $dockerFileName does not existing.  Not every image exists in every channel.  Skipping."
        if($CI.IsPresent)
        {
            throw $message
        }

        Write-Warning $message
        continue
    }

    $meta = Get-DockerImageMetaData -Path $metaJsonPath
    if($meta.tagTemplates.count -gt 0)
    {
        $tagsTemplates = $meta.tagTemplates
    }
    else
    {
        $tagsTemplates = Get-Content -Path $tagsJsonPath | ConvertFrom-Json
    }

    $getTagsExtraParams = @{}

    if($meta.ShortTags.count -gt 0)
    {
        $shortTags = @()
        foreach ($shortTag in $meta.ShortTags) {
            if(!$shortTag.KnownIssue -or $IncludeKnownIssues.IsPresent)
            {
                $shortTags += $shortTag.Tag
            }
        }

        $getTagsExtraParams.Add('ShortTags',$shortTags)
    }

    # Get the tag data for the image
    $tagData = @(& $scriptPath -CI:$CI.IsPresent @getTagsExtraParams | Where-Object {$_.FromTag})
    if($TagFilter)
    {
        $tagData = $tagData | Where-Object { $_.FromTag -match $TagFilter }
    }

    return [PSCustomObject]@{
        meta = $meta
        tagsTemplates = $tagsTemplates
        imagePath = $imagePath
        tagData = $tagData
    }
}
