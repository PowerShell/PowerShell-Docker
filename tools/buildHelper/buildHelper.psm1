# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Gets the current version of PowerShell from the PowerShell repo
# or formats the version based on the parameters

$parent = Join-Path -Path $PSScriptRoot -ChildPath '..'
$repoRoot = Join-Path -path $parent -ChildPath '..'
$modulePath = Join-Path -Path $repoRoot -ChildPath 'tools\getDockerTags'
Import-Module $modulePath -Force

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

        [Parameter(Mandatory, ParameterSetName="ExplicitVersionLts", HelpMessage="Gets the preview version.  Without this it gets the current stable version.")]
        [Parameter(Mandatory, ParameterSetName='Lts', HelpMessage="Gets the lts version.  Without this it gets the current stable version.")]
        [switch] $Lts,

        [Parameter(ParameterSetName="LookupVersion",HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [Parameter(ParameterSetName="ExplicitVersion",HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [Parameter(ParameterSetName="ExplicitVersionPreview",HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [Parameter(ParameterSetName="ExplicitVersionServicing",HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [Parameter(ParameterSetName="ExplicitVersionLts", HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [Parameter(ParameterSetName='Servicing', HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [Parameter(ParameterSetName='Preview', HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [Parameter(ParameterSetName='Lts', HelpMessage="Gets the linux package (docker tags use the standard format) format of the version.  This only applies to preview versions, but is always safe to use for linux packages.")]
        [switch] $Linux,

        [Parameter(Mandatory,ParameterSetName="ExplicitVersion", HelpMessage="Don't lookup version, just transform this standardized version based on the other parameters.")]
        [Parameter(Mandatory,ParameterSetName="ExplicitVersionServicing", HelpMessage="Don't lookup version, just transform this standardized version based on the other parameters.")]
        [Parameter(Mandatory,ParameterSetName="ExplicitVersionPreview", HelpMessage="Don't lookup version, just transform this standardized version based on the other parameters.")]
        [Parameter(Mandatory, ParameterSetName="ExplicitVersionLts", HelpMessage="Don't lookup version, just transform this standardized version based on the other parameters.")]
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
        elseif ($Lts.IsPresent) {
            $ltsReleaseTag = $metaData.LtsReleaseTag
            if (-not $ltsReleaseTag) {
                $metaData.PreviewReleaseTag
            }
            else {
                $ltsReleaseTag
            }
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
        [Parameter(HelpMessage="Filters returned list to stable or preview images. Default to all images.")]
        [ValidateSet('stable','preview','servicing','all','community-stable','lts')]
        [string[]]
        $Channel='all'
    )

    # Get the names of the builds.
    $releasePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\release'
    $stablePath = Join-Path -Path $releasePath -ChildPath 'stable'
    $ltsPath = Join-Path -Path $releasePath -ChildPath 'lts'
    $previewPath = Join-Path -Path $releasePath -ChildPath 'preview'
    $servicingPath = Join-Path -Path $releasePath -ChildPath 'servicing'
    $communityStablePath = Join-Path -Path $releasePath -ChildPath 'community-stable'

    if ($Channel -in 'stable', 'all')
    {
        Get-ChildItem -Path $stablePath -Directory | Select-Object -ExpandProperty Name | Write-Output
    }

    if ($Channel -in 'servicing', 'all')
    {
        Get-ChildItem -Path $servicingPath -Directory | Select-Object -ExpandProperty Name | Write-Output
    }

    if ($Channel -in 'lts', 'all')
    {
        Get-ChildItem -Path $ltsPath -Directory | Select-Object -ExpandProperty Name | Write-Output
    }

    if ($Channel -in 'preview', 'all')
    {
        Get-ChildItem -Path $previewPath -Directory | Select-Object -ExpandProperty Name | Where-Object { $dockerFileNames -notcontains $_ } | Write-Output
    }

    if ($Channel -in 'community-stable', 'all')
    {
        Get-ChildItem -Path $communityStablePath -Directory | Select-Object -ExpandProperty Name | Write-Output
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
    $PackageFormat

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

    [string]
    $SubImage

    [string]
    $SubRepository

    [string]
    $FullRepository

    [string[]]
    $OptionalTests

    [PSCustomObject]
    $TestProperties = ([PSCustomObject]@{})

    [PSCustomObject]
    $TagMapping

    [bool]
    $UseAcr = $false

    [bool]
    $IsBroken = $false

    [bool]
    $ContinueOnError = $false
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
    $ParameterAttr = [System.Management.Automation.ParameterAttribute]::new()
    $ParameterAttr.ParameterSetName = $ParameterSetName
    $ParameterAttr.Mandatory = $true
    $Attributes.Add($ParameterAttr) > $null
}

class DockerVersions {
    [string] $WindowsVersion
    [string] $LinuxVersion
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
        $StableVersion,

        [string]
        $LtsVersion
    )

    Write-Verbose "Getting Version for $Channel - servicing: $ServicingVersion; Preview: $PreviewVersion; stable: $stableVersion; stable: $ltsVersion"

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
        'lts$' {
            if($LtsVersion){
                $versionExtraParams['Version'] = $LtsVersion
            }

            $windowsVersion = Get-PowerShellVersion -Lts @versionExtraParams
            $linuxVersion = Get-PowerShellVersion -Lts -Linux @versionExtraParams
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

    return [DockerVersions] @{
        WindowsVersion = $windowsVersion
        LinuxVersion = $linuxVersion
    }
}

class DockerImageFullMetaData
{
    [DockerImageMetaData] $Meta
    [string[]] $TagsTemplates
    [string] $ImagePath
    # this is UpstreamDockerTagData[]
    [object[]] $TagData
    [System.Collections.Generic.Dictionary[object,TagData]] $ActualTagDataByGroup
    [string] $PSVersion
    [string] $BaseImage
    [string] $FullRepository
    [string] $Name
    [string] $Channel
}

class UpstreamImageTagData
{
    [string] $Type
    [string] $Tag
    [string] $FromTag
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
        $linuxVersion,

        [object[]]
        $TagData,

        [string]
        $BaseImage,

        [string]
        $BaseRepositry,

        [switch]
        $Strict,

        [string]
        $FromTag,

        [string]
        $Channel
    )

    $imagePath = Join-Path -Path $ChannelPath -ChildPath $dockerFileName
    $scriptPath = Join-Path -Path $imagePath -ChildPath 'getLatestTag.ps1'
    $metaJsonPath = Join-Path -Path $imagePath -ChildPath 'meta.json'

    if ($env:FULL_TAG) {
        $fullTag = $env:FULL_TAG
    }
    else {
        $fullTag = (Get-Date).ToString("yyyyMMdd")
    }

    $meta = Get-DockerImageMetaData -Path $metaJsonPath

    # if the image is broken and we shouldn't include known issues,
    # do this
    if(!$IncludeKnownIssues.IsPresent -and $meta.Broken -ne $null) {
        return
    }

    $tagsTemplates = $meta.tagTemplates

    $getTagsExtraParams = @{}

    if($meta.ShortTags.count -gt 0)
    {
        $shortTags = @()
        foreach ($shortTag in $meta.ShortTags) {
            $shortTags += $shortTag.Tag
        }

        $getTagsExtraParams.Add('ShortTags', $shortTags)
    }

    if(!$TagData)
    {
        if((Test-Path $scriptPath) )
        {
            # Get the tag data for the image
            $tagDataFromScript = @(& $scriptPath -CI:$CI.IsPresent @getTagsExtraParams | Where-Object {$_.FromTag})
            Write-Verbose "tdfs count:$($tagDataFromScript.count)-$($Strict.IsPresent)"
            if($tagDataFromScript.count -eq 0 -and $Strict.IsPresent)
            {
                throw "Did not get tag data from script for $scriptPath!"
            }

            if($TagFilter)
            {
                $tagDataFromScript = @($tagDataFromScript | Where-Object { $_.FromTag -match $TagFilter })
            }
        }
        else {
            Write-Verbose "getting docker tag list" -Verbose
            if($shortTags)
            {
                $tagDataFromScript = Get-DockerTagList -ShortTag $shortTags -FullTag $fullTag
            }
        }
    }
    elseif ($meta.TagMapping)
    {
        foreach($regex in $meta.TagMapping.PSObject.Properties.Name)
        {
            if($BaseImage -match $regex)
            {
                $tagName = $meta.TagMapping.$regex
                $tagDataFromScript = @(
                    [UpstreamImageTagData]@{
                        Type='Full'
                        Tag=$tagName
                        FromTag = $FromTag
                    }
                )
            }
        }
    }
    else
    {
        $tagDataFromScript = $TagData
    }

    if ($meta.FullRepository)
    {
        $fullRepository = $meta.FullRepository
    }
    else
    {
        $fullRepository = $BaseRepositry
        if ($meta.SubRepository)
        {
            $fullRepository += '/{0}' -f $meta.SubRepository
        }
        elseif ($TagData)
        {
            $subImageName = Split-Path -leaf -Path $DockerFileName
            $fullRepository += '/{0}' -f $subImageName
        }
    }

    $actualTagDataByGroup = [System.Collections.Generic.Dictionary[object,TagData]]::new()
    foreach ($tagGroup in ($tagDataFromScript | Group-Object -Property 'FromTag'))
    {
        $actualTagDataByGroup[$tagGroup] = Get-TagData -TagsTemplates $tagsTemplates -TagGroup $tagGroup -Version $Version -ImageName $ImageName -Repository $fullRepository
    }

    $psversion = $Version
    if($meta.ShouldUseLinuxVersion())
    {
        $psversion = $linuxVersion
    }

    return [DockerImageFullMetaData]@{
        meta = $meta
        tagsTemplates = $tagsTemplates
        imagePath = $imagePath
        tagData = $tagDataFromScript
        ActualTagDataByGroup = $actualTagDataByGroup
        PSVersion = $psversion
        BaseImage = $BaseImage
        FullRepository = $fullRepository
        Name = $dockerFileName
        Channel = $Channel
    }
}

$toolsPath = Join-Path -Path $PSScriptRoot -ChildPath '..'
$rootPath = Join-Path -Path $toolsPath -ChildPath '..'
$testsPath = Join-Path -Path $rootPath -ChildPath 'tests'

class DockerTestParams
{
    [DockerTestArgs] $TestArgs
    [string] $ImageName
}

class DockerTestArgs
{
    [string[]] $Tags
    [System.Collections.Generic.Dictionary[string,string]] $BuildArgs
    [string] $ContextPath
    [string] $OS
    [string] $ExpectedVersion
    [bool] $SkipVerification
    [bool] $SkipWebCmdletTests
    [bool] $SkipGssNtlmSspTests
    [string] $BaseImage
    [string[]] $OptionalTests
    [PSCustomObject] $TestProperties
    [string] $Channel
    [bool] $UseAcr
}

function Get-TestParams
{
    param(
        [string]
        $dockerFileName,
        [string]
        $psversion,
        [SasData]
        $SasData,
        [string]
        $actualChannel,
        [TagData]
        $actualTagData,
        [string]
        $actualVersion,
        [DockerImageFullMetaData]
        $allMeta,
        [switch]
        $CI,
        [string]
        $BaseImage
    )

    Write-Verbose -Message "To be tested, repository: $($allMeta.FullRepository) fromTag: $($actualTagData.FromTag) Tag: $($actualTagData.ActualTag) PSversion: $psversion" -Verbose
    $contextPath = Join-Path -Path $allMeta.imagePath -ChildPath 'docker'
    $script:ErrorActionPreference = 'stop'
    Import-Module (Join-Path -Path $testsPath -ChildPath 'containerTestCommon.psm1') -Force
    if ($allMeta.meta.IsLinux) {
        $os = 'linux'
    }
    else {
        $os = 'windows'
    }

    $skipVerification = $false
    if($dockerFileName -eq 'nanoserver' -and $CI.IsPresent)
    {
        Write-Verbose -Message "Skipping verification of $($actualTagData.ActualTags[0]) in CI because the CI system only supports LTSC and at least 1709 is required." -Verbose
        # The version of nanoserver in CI doesn't have all the changes needed to verify the image
        $skipVerification = $true
    }

    # for the image name label, always use the official image name
    $imageNameParam = "mcr.microsoft.com/$($allMeta.FullRepository):" + $actualTagData.TagList[0]
    if($actualChannel -like 'community-*')
    {
        # use the image name for pshorg for community images
        $imageNameParam = 'pshorg/powershellcommunity:' + $actualTagData.TagList[0]
    }

    $packageVersion = $psversion

    # if the package name ends with rpm
    # then replace the - in the filename with _ as fpm creates the packages this way.
    if($allMeta.meta.PackageFormat -and $allMeta.meta.PackageFormat -match 'rpm$')
    {
        $packageVersion = $packageVersion -replace '-', '_'
    }

    $buildArgs = [System.Collections.Generic.Dictionary[string,string]]::new()
    $buildArgs['fromTag'] = $actualTagData.FromTag
    $buildArgs['PS_VERSION'] = $psversion
    $buildArgs['PACKAGE_VERSION'] = $packageVersion
    $buildArgs['IMAGE_NAME'] = $imageNameParam
    $buildArgs['BaseImage'] = $BaseImage

    if ($allMeta.meta.PackageFormat)
    {
        if($sasData.sasUrl)
        {
            $packageUrl = [System.UriBuilder]::new($sasData.sasBase)

            $previewTag = ''
            if($psversion -like '*-*')
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
            if($psversion -like '*-*')
            {
                $previewTag = '-preview'
            }

            $packageName = $allMeta.meta.PackageFormat -replace '\${PS_VERSION}', $packageVersion
            $packageName = $packageName -replace '\${previewTag}', $previewTag
            $containerName = 'v' + ($psversion -replace '~', '-')
            $packageUrl.Path = $packageUrl.Path + $containerName + '/' + $packageName
            $buildArgs.Add('PS_PACKAGE_URL', $packageUrl.ToString())
        }
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
        BaseImage = $BaseImage
        OptionalTests = $allMeta.meta.OptionalTests
        TestProperties = $allMeta.meta.TestProperties
        Channel = $actualChannel
        UseAcr = $allMeta.meta.UseAcr
    }

    return [DockerTestParams] @{
        TestArgs = $testArgs
        ImageName = $actualTagData.ActualTags[0]
    }
}

class TagData{
    [string[]] $TagList
    [string] $FromTag
    [string[]] $ActualTags
    [string] $ActualTag
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
        $ImageName,
        [string]
        $Repository
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
            $actualTags += "${ImageName}/${Repository}:$actualTag"
            $tagList += $actualTag
            $fromTag = $Tag.FromTag
        }
    }

    return [TagData]@{
        TagList = $tagList
        FromTag = $fromTag
        ActualTags = $actualTags
        ActualTag = $actualTag
    }
}

class SasData{
    [string] $SasUrl
    [Uri] $SasUri
    [string] $SasBase
    [string] $SasQuery
}

function New-SasData
{
    param(
        [parameter(Mandatory)]
        [string]
        $SasUrl
    )

    $sasUri = [uri]$SasUrl
    $sasBase = $sasUri.GetComponents([System.UriComponents]::Path -bor [System.UriComponents]::Scheme -bor [System.UriComponents]::Host ,[System.UriFormat]::Unescaped)

    # The UriBuilder used later adds the ? even if it is already there on Windows
    # and will add it if it is not there on non-windows
    $sasQuery = $sasUri.Query -replace '^\?', ''

    return [SasData]@{
        SasUrl = $SasUrl
        SasUri = $sasUri
        SasBase = $sasBase
        SasQuery = $sasQuery
    }
}
