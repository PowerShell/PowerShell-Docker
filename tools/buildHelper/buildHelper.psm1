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
        $ChannelPath,

        [string]
        $Version,

        [string]
        $ImageName,

        [string]
        $linuxVersion
    )

    $imagePath = Join-Path -Path $ChannelPath -ChildPath $dockerFileName
    $scriptPath = Join-Path -Path $imagePath -ChildPath 'getLatestTag.ps1'
    $metaJsonPath = Join-Path -Path $imagePath -ChildPath 'meta.json'

    # skip an image if it doesn't exist
    if(!(Test-Path $scriptPath))
    {
        return
    }

    $meta = Get-DockerImageMetaData -Path $metaJsonPath
    $tagsTemplates = $meta.tagTemplates

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

    $actualTagDataByGroup = @{}
    foreach ($tagGroup in ($tagData | Group-Object -Property 'FromTag'))
    {
        $actualTagDataByGroup[$tagGroup] = Get-TagData -TagsTemplates $tagsTemplates -TagGroup $tagGroup -Version $Version -ImageName $ImageName
    }

    $psversion = $Version
    if($meta.ShouldUseLinuxVersion())
    {
        $psversion = $linuxVersion
    }

    return [PSCustomObject]@{
        meta = $meta
        tagsTemplates = $tagsTemplates
        imagePath = $imagePath
        tagData = $tagData
        ActualTagDataByGroup = $actualTagDataByGroup
        PSVersion = $psversion
    }
}

$toolsPath = Join-Path -Path $PSScriptRoot -ChildPath '..'
$rootPath = Join-Path -Path $toolsPath -ChildPath '..'
$testsPath = Join-Path -Path $rootPath -ChildPath 'tests'

function Get-TestParams
{
    param(
        [string]
        $dockerFileName,
        [string]
        $psversion,
        [Object]
        $SasData,
        [string]
        $actualChannel,
        [object]
        $actualTagData,
        [string]
        $actualVersion,
        [object]
        $allMeta,
        [switch]
        $CI
    )

    Write-Verbose -Message "Adding the following to the list to be tested, fromTag: $($actualTagData.FromTag) Tag: $($actualTagData.ActualTag) PSversion: $psversion" -Verbose
    $contextPath = Join-Path -Path $allMeta.imagePath -ChildPath 'docker'
    $vcf_ref = git rev-parse --short HEAD
    $script:ErrorActionPreference = 'stop'
    Import-Module (Join-Path -Path $testsPath -ChildPath 'containerTestCommon.psm1') -Force
    if ($allMeta.meta.IsLinux) {
        $os = 'linux'
    }
    else {
        $os = 'windows'
    }

    $skipVerification = $false
    <#if($dockerFileName -eq 'nanoserver' -and $CI.IsPresent)
    {
        Write-Verbose -Message "Skipping verification of $($actualTagData.ActualTags[0]) in CI because the CI system only supports LTSC and at least 1709 is required." -Verbose
        # The version of nanoserver in CI doesn't have all the changes needed to verify the image
        $skipVerification = $true
    }#>

    # for the image name label, always use the official image name
    $imageNameParam = 'mcr.microsoft.com/powershell:' + $actualTagData.TagList[0]
    if($actualChannel -like 'community-*')
    {
        # use the image name for pshorg for community images
        $imageNameParam = 'pshorg/powershellcommunity:' + $actualTagData.TagList[0]
    }

    $packageVersion = $psversion

    # if the package name ends with rpm
    # then replace the - in the filename with _ as fpm creates the packages this way.
    if($allMeta.meta.PackageFormat -match 'rpm$')
    {
        $packageVersion = $packageVersion -replace '-', '_'
    }

    $buildArgs =  @{
            fromTag = $actualTagData.FromTag
            PS_VERSION = $psVersion
            PACKAGE_VERSION = $packageVersion
            VCS_REF = $vcf_ref
            IMAGE_NAME = $imageNameParam
        }

    if($sasData.sasUrl)
    {
        $packageUrl = [System.UriBuilder]::new($sasData.sasBase)

        $previewTag = ''
        if($actualChannel -like '*preview*')
        {
            $previewTag = '-preview'
        }

        $packageName = $allMeta.meta.PackageFormat -replace '\${PS_VERSION}', $packageVersion
        $packageName = $packageName -replace '\${previewTag}', $previewTag
        $containerName = 'v' + ($psversion -replace '\.', '-') -replace '~', '-'
        $packageUrl.Path = $packageUrl.Path + $containerName + '/' + $packageName
        $packageUrl.Query = $sasData.sasQuery
        if($allMeta.meta.Base64EncodePackageUrl)
        {
            $urlBytes = [System.Text.Encoding]::Unicode.GetBytes($packageUrl.ToString())
            $encodedUrl =[Convert]::ToBase64String($urlBytes)
            $buildArgs.Add('PS_PACKAGE_URL_BASE64', $encodedUrl)
        }
        else
        {
            $buildArgs.Add('PS_PACKAGE_URL', $packageUrl.ToString())
        }
    }
    else
    {
        $packageUrl = [System.UriBuilder]::new('https://github.com/PowerShell/PowerShell/releases/download/')

        $previewTag = ''
        if($actualChannel -like '*preview*')
        {
            $previewTag = '-preview'
        }

        $packageName = $allMeta.meta.PackageFormat -replace '\${PS_VERSION}', $packageVersion
        $packageName = $packageName -replace '\${previewTag}', $previewTag
        $containerName = 'v' + ($psversion -replace '~', '-')
        $packageUrl.Path = $packageUrl.Path + $containerName + '/' + $packageName
        $buildArgs.Add('PS_PACKAGE_URL', $packageUrl.ToString())
    }

    $testArgs = @{
        tags = $actualTagData.ActualTags
        BuildArgs = $buildArgs
        ContextPath = $contextPath
        OS = $os
        ExpectedVersion = $actualVersion
        SkipVerification = $skipVerification
        SkipWebCmdletTests = $allMeta.meta.SkipWebCmdletTests
        SkipGssNtlmSspTests = $allMeta.meta.SkipGssNtlmSspTests
    }

    return [PSCustomObject]@{
        TestArgs = $testArgs
        ImageName = $actualTagData.ActualTags[0]
    }
}

function Get-TagData
{
    param(
        [string[]]
        $TagsTemplates,
        [object]
        $TagGroup,
        [string]
        $Version,
        [string]
        $ImageName
    )

    $actualTags = @()
    $tagList = @()
    foreach($tag in $tagGroup.Group) {
        foreach ($tagTemplate in $tagsTemplates) {
            # replace the tag token with the tag
            if ($tagTemplate -match '#tag#') {
                $actualTag = $tagTemplate -replace '#tag#', $tag.Tag
            }
            elseif ($tagTemplate -match '#shorttag#' -and $tag.Type -eq 'Short') {
                $actualTag = $tagTemplate -replace '#shorttag#', $tag.Tag
            }
            elseif ($tagTemplate -match '#fulltag#' -and $tag.Type -eq 'Full') {
                $actualTag = $tagTemplate -replace '#fulltag#', $tag.Tag
            }
            else {
                # skip if the type of tag token doesn't match the type of tag
                Write-Verbose -Message "Skipping $($tag.Tag) - $tagTemplate, token doesn't match template"
                continue
            }

            # Replace the the psversion token with the powershell version in the tag
            $actualTag = $actualTag -replace '#psversion#', $Version
            $actualTag = $actualTag.ToLowerInvariant()
            $actualTags += "${ImageName}:$actualTag"
            $tagList += $actualTag
            $fromTag = $Tag.FromTag
        }
    }

    return [PSCustomObject]@{
        TagList = $tagList
        FromTag = $fromTag
        ActualTags = $actualTags
        ActualTag = $actualTag
    }
}
