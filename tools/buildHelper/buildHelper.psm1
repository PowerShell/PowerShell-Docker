# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Gets the current version of PowerShell from the PowerShell repo
# or formats the version based on the parameters

$parent = Join-Path -Path $PSScriptRoot -ChildPath '..'
$repoRoot = Join-Path -path $parent -ChildPath '..'
$modulePath = Join-Path -Path $repoRoot -ChildPath 'tools\getDockerTags'
Import-Module $modulePath -Force

$repoMetaData = $null
function Get-RepoMetaData {
    if (!$script:repoMetaData) {
        Write-Verbose "getting metadata from repo" -Verbose
        $script:repoMetaData = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json'
    }

    return $script:repoMetaData
}

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
        $metaData = Get-RepoMetaData

        $releaseTag = if ($Preview.IsPresent) {
            $metaData.PreviewReleaseTag
        }
        elseif ($Servicing.IsPresent) {
            $metaData.ServicingReleaseTag
        }
        elseif ($Lts.IsPresent) {
            $ltsReleaseTag = $metaData.LtsReleaseTag[0]
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

    return $retVersion
}

function Get-ChannelPath
{
    param(
        [Parameter(Mandatory)]
        [string]
        $Channel
    )

    $relativePath = $channelData | Where-Object {$_.Name -eq $Channel} | Select-Object -ExpandProperty Path -First 1
    $repoRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\..'
    $resolvedRepoRoot = (Resolve-Path -Path $repoRoot).ProviderPath
    return Join-Path -Path $resolvedRepoRoot -ChildPath $relativePath
}

function Get-ChannelEndOfLife {
    param(
        [Parameter(Mandatory)]
        [string]
        $Channel
    )

    $endOfLife = $channelData | Where-Object { $_.Name -eq $Channel } | Select-Object -ExpandProperty EndOfLife -First 1
    return $endOfLife
}

function Get-ChannelPackageTag
{
    param(
        [Parameter(Mandatory)]
        [string]
        $Channel
    )

    return $channelData | Where-Object {$_.Name -eq $Channel} | Select-Object -ExpandProperty PackageTag -First 1
}

function Get-PwshInstallVersion
{
    param(
        [Parameter(Mandatory)]
        [string]
        $Channel
    )

    return $channelData | Where-Object {$_.Name -eq $Channel} | Select-Object -ExpandProperty pwshInstallVersion -First 1
}

function Get-ChannelTagPrefix {
    param(
        [Parameter(Mandatory)]
        [string]
        $Channel
    )

    return $channelData | Where-Object {$_.Name -eq $Channel} | Select-Object -ExpandProperty TagPrefix -First 1
}

function Get-ChannelNames {
    $channelData = Get-ChannelData
    $channelNames = $channelData | Select-Object -ExpandProperty Name
    return $channelNames
}

# Gets list of images names
function Get-ImageList
{
    param(
        [Parameter(HelpMessage="Filters returned list to stable or preview images. Default to all images.")]
        [string[]]
        $Channel='all'
    )

    $channelList = Get-ChannelNames | Where-Object {$_ -eq $Channel -or $Channel -eq 'all'}

    foreach($channelName in $channelList){
        $channelPath = Get-ChannelPath -Channel $channelName
        Get-ChildItem -Path $channelPath -Directory | Select-Object -ExpandProperty Name | Write-Output
    }
}

enum DistributionState {
    Unknown
    ImageCreation
    Validating
    Validated
    EndOfLife
}

class DockerImageMetaData {
    [void] Init() {
        if (!$this.tagTemplates -and $this.ShortDistroName) {
            $this.tagTemplates = @(
                '#psversion#-' + $this.ShortDistroName + '-#shorttag#'
                $this.ShortDistroName + '-#shorttag#'
            )
        }

        if (!$this.TagTemplates -and !$this.ShortDistroName)
        {
            throw "Image does not contain tag templates and short distro name and must contain one."
        }

        switch -RegEx ($this.GetDistributionState()) {
            'Unknown|Validating' {
                $this.OsVersion = $this.OsVersion + ' (In Validation)'
            }
            'EndOfLife' {
                # add this back if we get the EOL information to be accurate
                # $this.OsVersion = $this.OsVersion + ' (End of Life)'
            }
        }
    }

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
    $TagTemplates

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

    [string]
    $Architecture = 'amd64'

    [bool]
    $IsBroken = $false

    [bool]
    $ContinueOnError = $false

    [string[]]
    $ManifestLists = @()

    [bool]
    $IsPrivate = $false

    [datetime]
    $EndOfLife = (Get-Date).Date.AddDays(7)

    [DistributionState]
    $DistributionState =[DistributionState]::Unknown

    [DistributionState] GetDistributionState() {
        if ($this.EndOfLife -lt (Get-Date)) {
            return [DistributionState]::EndOfLife
        }

        return $this.DistributionState
    }


    [string] $ShortDistroName

    [bool]$UseInCI = $true
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
            $dockerImageMeta = [DockerImageMetaData] $meta
            $dockerImageMeta.Init()
            return $dockerImageMeta
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
        $ParameterSetName,
        [bool]
        $Mandatory = $true
    )
    $ParameterAttr = [System.Management.Automation.ParameterAttribute]::new()
    $ParameterAttr.ParameterSetName = $ParameterSetName
    $ParameterAttr.Mandatory = $Mandatory
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
        $BaseRepository,

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

    $meta = Get-DockerImageMetaData -Path $metaJsonPath

    # if the image is broken and we shouldn't include known issues,
    # do this
    if( !$IncludeKnownIssues.IsPresent -and $meta.IsBroken) {
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
            Write-Verbose "Getting tags using script: $scriptPath" -Verbose
            # Get the tag data for the image
            $tagDataFromScript = @(& $scriptPath -CI:$CI.IsPresent @getTagsExtraParams | Where-Object {$_.FromTag})
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
            Write-Verbose "getting docker tag list"
            if($shortTags)
            {
                $tagDataFromScript = Get-DockerTagList -ShortTag $shortTags
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
        $scope = if ($meta.IsPrivate) { "internal" } else { "public" }
        $fullRepository = $scope + '/' + $BaseRepository

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
    $tagPrefix = Get-ChannelTagPrefix -Channel $Channel
    foreach ($tagGroup in ($tagDataFromScript | Group-Object -Property 'FromTag'))
    {
        $actualTagDataByGroup[$tagGroup] = Get-TagData -TagsTemplates $tagsTemplates -TagGroup $tagGroup -Version $Version -ImageName $ImageName -Repository $fullRepository -TagPrefix $tagPrefix
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
    [string] $LoadPathParentFolder
    [string] $ShortImageName
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

    $loadPathParent = "" # will be "main" or "test" folder name
    $imageName = "" # also capture image name (without test-deps part) as it may be needed for load tests to derive <imageName>.tar file name
    if ($dockerFileName.Contains("test-deps"))
    {
        $loadPathParent = "test"
        $dockerFileParts = $dockerFileName.Split("test-deps", [System.StringSplitOptions]::RemoveEmptyEntries)
        $imageName = $dockerFileParts[0].TrimEnd("\","/")
    }
    else
    {
        $loadPathParent = "main"
        $imageName = $dockerFileName
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
    $buildArgs['PS_INSTALL_VERSION'] = Get-PwshInstallVersion -Channel $actualChannel

    if ($allMeta.meta.PackageFormat)
    {
        if($sasData.sasUrl)
        {
            $packageUrl = [System.UriBuilder]::new($sasData.sasBase)

            $channelTag = Get-ChannelPackageTag -Channel $actualChannel

            $packageName = $allMeta.meta.PackageFormat -replace '\${PS_VERSION}', $packageVersion
            $packageName = $packageName -replace '\${channelTag}', $channelTag
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

            $channelTag = Get-ChannelPackageTag -Channel $actualChannel

            $packageName = $allMeta.meta.PackageFormat -replace '\${PS_VERSION}', $packageVersion
            $packageName = $packageName -replace '\${channelTag}', $channelTag
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
        LoadPathParentFolder = $loadPathParent
        ShortImageName = $imageName #instead of the official image name (like mcr.microsoft.com/*) just alpine316 for example
    }

    return [DockerTestParams] @{
        TestArgs = $testArgs
        ImageName = $actualTagData.ActualTags[0]
    }
}

function Get-SASBuildArgs
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
    # $contextPath = Join-Path -Path $allMeta.imagePath -ChildPath 'docker'
    $script:ErrorActionPreference = 'stop'
    # Import-Module (Join-Path -Path $testsPath -ChildPath 'containerTestCommon.psm1') -Force
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
    Write-Verbose -Verbose "made it here"
    $imageNameParam = "mcr.microsoft.com/$($allMeta.FullRepository):" + $actualTagData.TagList[0]
    Write-Verbose -Verbose "past first indexing"
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
    $buildArgs['PS_INSTALL_VERSION'] = Get-PwshInstallVersion -Channel $actualChannel

    if ($allMeta.meta.PackageFormat)
    {
        if($sasData.sasUrl)
        {
            $packageUrl = [System.UriBuilder]::new($sasData.sasBase)

            $channelTag = Get-ChannelPackageTag -Channel $actualChannel

            $packageName = $allMeta.meta.PackageFormat -replace '\${PS_VERSION}', $packageVersion
            $packageName = $packageName -replace '\${channelTag}', $channelTag
            $containerName = 'v' + ($psversion) -replace '~', '-'
            $packageUrl.Path = $packageUrl.Path + $containerName + '/' + $packageName
            $packageUrl.Query = $sasData.sasQuery
            if($allMeta.meta.Base64EncodePackageUrl)
            {
                $urlBytes = [System.Text.Encoding]::Unicode.GetBytes($packageUrl.Uri.ToString())
                $encodedUrl =[Convert]::ToBase64String($urlBytes)
                $buildArgs.Add('PS_PACKAGE_URL_BASE64', $encodedUrl)
            }
            else
            {
                $buildArgs.Add('PS_PACKAGE_URL', $packageUrl.Uri.ToString())
            }
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

    $buildArgsString = ""
    $buildArgsDict = $testArgs.BuildArgs

    foreach($argKey in $buildArgsDict.Keys)
    {
        $value = $buildArgsDict[$argKey]
        if($UseAcr.IsPresent -and $env:ACR_NAME -and $value -match '&')
        {
            throw "$argKey contains '&' and this is not allowed in ACR using the az cli"
        }

        if($value)
        {
            $buildArgsString += " --build-arg $argKey=$value"
        }
    }

    return $buildArgsString
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
        [Microsoft.PowerShell.Commands.GroupInfo[]]
        $TagGroup,
        [string]
        $Version,
        [string]
        $ImageName,
        [string]
        $Repository,
        [string]
        $TagPrefix
    )

    $actualTags = @()
    $tagList = @()
    foreach ($tagTemplate in $tagsTemplates) {
        $templateActualTags = Format-TagTemplate -TagTemplate $tagTemplate -TagGroup $TagGroup -Version $Version
        foreach ($actualTag in $templateActualTags) {
            if($TagPrefix) {
                $actualTag = $TagPrefix + '-' + $actualTag
            }

            $actualTags += "${ImageName}/${Repository}:$actualTag"
            $tagList += $actualTag
        }

        $fromTag = $TagGroup.Name
    }

    # remove any duplicate tags from the template formatting
    $actualTags = $actualTags | Select-Object -Unique
    $tagList = $tagList | Select-Object -Unique

    return [TagData]@{
        TagList = $tagList
        FromTag = $fromTag
        ActualTags = $actualTags
        ActualTag = $actualTag
    }
}

function Format-TagTemplate {
    param(
        [parameter(Mandatory)]
        [string]
        $TagTemplate,

        [parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.GroupInfo[]]
        $TagGroup,

        [parameter(Mandatory)]
        [string]
        $Version
    )

    $twoPartVersion = ($Version -split '\.(?=\d+([-]|$))')[0]

    if(!$twoPartVersion)
    {
        throw "Version '$Version' is not in the expected format 'x.y.z' or 'x.y.z-preview.n'"
    }

    $currentTag = $TagTemplate

    $actualMatrixTagTemplates = @()
    foreach($tag in $tagGroup.Group) {
        # replace the tag token with the tag
        if ($currentTag -match '#tag#') {
            $actualMatrixTagTemplates += $currentTag.Replace('#tag#', $tag.Tag)
        }
        elseif ($currentTag -match '#shorttag#' -and $tag.Type -eq 'Short') {
            $actualMatrixTagTemplates += $currentTag.Replace('#shorttag#', $tag.Tag)
        }
    }

    $actualTags = @()
    foreach ($currentTag in $actualMatrixTagTemplates) {
        # Replace the the psversion token with the powershell version in the tag
        $currentTag = $currentTag -replace '#psversion#', $twoPartVersion
        $currentTag = $currentTag.ToLowerInvariant()
        $actualTags += $currentTag
    }

    return $actualTags;
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

class ChannelData {
    [string] $Name
    [string] $Path
    [string] $TagPrefix
    [string] $PwshInstallVersion
    [string] $PackageTag
}

[ChannelData[]] $channelData = $null
function Get-ChannelData {
    if (!$Script:channelData) {
        $jsonPath = Join-Path $PSScriptRoot -ChildPath 'channels.json'
        $Script:channelData = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json -Depth 100 -AsHashtable
    }

    return $Script:channelData
}

function Invoke-PesterWrapper {
    param(
        [string]
        $Script,

        [string]
        $OutputFile,

        [hashtable]
        $ExtraParams
    )

    Write-Verbose "Launching pester with $($ExtraParams|Out-String)" -Verbose

    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    if(!(Get-Module "pester" -ListAvailable -ErrorAction Ignore | Where-Object {$_.Version -le "4.99" -and $_.Version -gt "4.00"}) -or $ForcePesterInstall.IsPresent)
    {
        Install-module Pester -Scope CurrentUser -Force -MaximumVersion 4.99 -Repository PSGallery -SkipPublisherCheck -Verbose
    }

    Remove-Module Pester -Force -ErrorAction SilentlyContinue
    Import-Module pester -MaximumVersion 4.99 -Scope Global -Verbose

    Write-Verbose -Message "logging to $OutputFile" -Verbose
    $results = $null
    $results = Invoke-Pester -Script $Script -OutputFile $OutputFile -PassThru -OutputFormat NUnitXml @extraParams
    if(!$results -or $results.FailedCount -gt 0 -or !$results.TotalCount)
    {
        throw "Build or tests failed.  Passed: $($results.PassedCount) Failed: $($results.FailedCount) Total: $($results.TotalCount)"
    }
}

# Sets a build variable
Function Set-BuildVariable
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Value,

        [switch]
        $IsOutput
    )

    $IsOutputString = if ($IsOutput) { 'true' } else { 'false' }
    $command = "vso[task.setvariable variable=$Name;isOutput=$IsOutputString]$Value"

    # always log command to make local debugging easier
    Write-Verbose -Message "sending command: $command" -Verbose

    if ($env:TF_BUILD) {
        # In VSTS
        Write-Host "##$command"
        # The variable will not show up until the next task.
    }

    # Setting in the current session for the same behavior as the CI and to make it show up in the same task
    Set-Item env:/$name -Value $Value
}

Function ConvertTo-SortedDictionary {
    param(
        [hashtable]
        $Hashtable
    )

    $sortedDictionary = [System.Collections.Generic.SortedDictionary[string,object]]::new()
    foreach($key in $Hashtable.Keys) {
        $sortedDictionary.Add($key, $Hashtable[$key])
    }
    return $sortedDictionary
}

function Get-StartOfYamlPopulated {
    param(
        [string]
        $Channel,

        [string]
        $YamlFilePath
    )

    if (!$YamlFilePath)
    {
        throw "Yaml file $YamlFilePath provided as parameter cannot be found."
    }
    
    $doubleSpace = " "*2

    Add-Content -Path $YamlFilePath -Value "parameters:"
    Add-Content -Path $YamlFilePath -Value "- name: channel"
    Add-Content -Path $YamlFilePath -Value "$($doubleSpace)default: 'preview'"
    Add-Content -Path $YamlFilePath -Value "- name: channelPath"
    Add-Content -Path $YamlFilePath -Value "$($doubleSpace)default: ''"
    Add-Content -Path $YamlFilePath -Value "- name: vmImage"
    Add-Content -Path $YamlFilePath -Value "$($doubleSpace)default: PSMMSUbuntu20.04-Secure"
    Add-Content -Path $YamlFilePath -Value "stages:"
    Add-Content -Path $YamlFilePath -Value "- stage: StageGenerateBuild_$Channel"
    Add-Content -Path $YamlFilePath -Value "$($doubleSpace)dependsOn: ['StageResolveVersionandYaml']"
    Add-Content -Path $YamlFilePath -Value "$($doubleSpace)displayName: Build $Channel"
    Add-Content -Path $YamlFilePath -Value "$($doubleSpace)jobs:"
}

function Get-TemplatePopulatedYaml {
    param(
        [string]
        $YamlFilePath,

        [psobject]
        $ImageInfo
    )

    if (!$YamlFilePath)
    {
        throw "Yaml file $YamlFilePath provided as parameter cannot be found."
    }

    $doubleSpace = " "*2
    $fourSpace = " "*4
    $sixSpace = " "*6

    $imageName = $ImageInfo.Name
    $artifactSuffix = $ImageInfo.Name.ToString().Replace("\", "_").Replace("-","_").Replace(".","")
    $architecture = $ImageInfo.Architecture
    $poolOS = $ImageInfo.IsLinux ? "linux" : "windows"
    $archBasedJobName = "Build_$($poolOS)_$($architecture)"

    if ($architecture -eq "arm32")
    {
        $architecture = "arm64" # we need to use hostArchicture arm64 for pool for arm32
    }

    Add-Content -Path $YamlFilePath -Value "$($doubleSpace)- template: /.vsts-ci/releaseJob.yml@self"
    Add-Content -Path $YamlFilePath -Value "$($fourSpace)parameters:"
    Add-Content -Path $YamlFilePath -Value "$($sixSpace)archName: '$archBasedJobName'" # ie: Build_Linux_arm32
    Add-Content -Path $YamlFilePath -Value "$($sixSpace)imageName: $imageName" # ie. imageName: alpine317\test-deps (since this differs from artifactSuffix for test-deps images only, we have a separate entry as the yaml param)
    Add-Content -Path $YamlFilePath -Value "$($sixSpace)artifactSuffix: $artifactSuffix" # i.e artifactSuffix: alpine317_test_deps 
    Add-Content -Path $YamlFilePath -Value "$($sixSpace)poolOS: '$poolOS'"
    if ($poolOS -eq "linux")
    {
        # only need to specify host architecture for the pool for linux
        Add-Content -Path $YamlFilePath -Value "$($sixSpace)poolHostArchitecture: '$architecture'"
        # only need to specify buildKitValue=1 for linux
        Add-Content -Path $YamlFilePath -Value "$($sixSpace)buildKitValue: 1"
    }
    else
    {
        Add-Content -Path $YamlFilePath -Value "$($sixSpace)poolHostVersion: '1ESWindows2022'"
        Add-Content -Path $YamlFilePath -Value "$($sixSpace)windowsContainerImageValue: 'onebranch.azurecr.io/windows/ltsc2022/vse2022:latest'"
        Add-Content -Path $YamlFilePath -Value "$($sixSpace)maxParallel: 3"
    }

    Add-Content -Path $YamlFilePath -Value "$($sixSpace)channel: `${{ parameters.channel }}"
    Add-Content -Path $YamlFilePath -Value "$($sixSpace)channelPath: `${{ parameters.channelPath }}"
}

function Get-ImgMetadataByChannel {
    param(
        [string]
        $Channel,

        [string]
        $FilePath,

        [object[]]
        $ImageInfoObjects
    )

    $imgsForChannelArr = @()
    foreach ($img in $ImageInfoObjects)
    {
        $imgName = $img.Name
        $tags = $img.Tags

        $tagStr = $tags -join " "
        $imgOS = $img.IsLinux ? "linux" : "windows"
        $imgMeta = @{}
        $imgMeta.Add("name", $imgName)
        $imgMeta.Add("tags", $tagStr)
        $imgMeta.Add("os", $imgOS)
        $imgsForChannelArr += $imgMeta
    }

    return $imgsForChannelArr
}
