# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Queue Docker image build for a particular image
# ** Expects to have OAuth access in the build**
# ** and the build service has to be granted permission to launch builds**
# The build is expected to have the following parameters:
#  - fromTag
#    - The tag of the image in the from statement which is being produced
#  - imageTag
#    - The tag of the produced image
#  - PowerShellVersion
#    - The version of powershell to put in the image
#  - DockerNamespace
#    - `public` to build for public consumption.
#    - `internal` to build for internal consumption.
[CmdletBinding()]

param(
    [Parameter(Mandatory, ParameterSetName="TestByName")]
    [Parameter(Mandatory, ParameterSetName="TestAll")]
    [switch]
    $Test,

    [Parameter(ParameterSetName="localBuildByName")]
    [Parameter(ParameterSetName="localBuildAll")]
    [Parameter(ParameterSetName="TestByName")]
    [Parameter(ParameterSetName="TestAll")]
    [switch]
    $Pull,

    [Parameter(Mandatory, ParameterSetName="GenerateTagsYaml")]
    [switch]
    $GenerateTagsYaml,

    [Parameter(Mandatory, ParameterSetName="localBuildByName")]
    [Parameter(Mandatory, ParameterSetName="localBuildAll")]
    [switch]
    $Build,

    [Parameter(ParameterSetName="localBuildByName")]
    [Parameter(ParameterSetName="localBuildAll")]
    [switch]
    $Push,

    [Parameter(ParameterSetName="localBuildByName")]
    [Parameter(ParameterSetName="localBuildAll")]
    [switch]
    $SkipTest,

    [Parameter(Mandatory, ParameterSetName="GetTagsByName")]
    [Parameter(Mandatory, ParameterSetName="GetTagsAll")]
    [switch]
    $GetTags,

    [Parameter(Mandatory, ParameterSetName="DupeCheckAll")]
    [switch]
    $CheckForDuplicateTags,

    [Parameter(Mandatory, ParameterSetName="TestAll")]
    [Parameter(Mandatory, ParameterSetName="localBuildAll")]
    [Parameter(Mandatory, ParameterSetName="GetTagsAll")]
    [switch]
    $All,

    [string]
    $ImageName = 'powershell.local',

    [string]
    $TestLogPostfix,

    [switch]
    $CI,

    [string]
    $TagFilter,

    [ValidateSet('stable','preview','servicing','community-stable','community-preview','community-servicing')]
    [Parameter(Mandatory, ParameterSetName="TestByName")]
    [Parameter(Mandatory, ParameterSetName="TestAll")]
    [Parameter(ParameterSetName="localBuildByName")]
    [Parameter(Mandatory, ParameterSetName="localBuildAll")]
    [Parameter(Mandatory, ParameterSetName="GetTagsByName")]
    [Parameter(Mandatory, ParameterSetName="GetTagsAll")]
    [Parameter(Mandatory, ParameterSetName="DupeCheckAll")]
    [Parameter(Mandatory, ParameterSetName="GenerateTagsYaml")]
    [string[]]
    $Channel='stable',

    [Parameter(ParameterSetName="localBuildByName")]
    [Parameter(ParameterSetName="localBuildAll")]
    [ValidateScript({([uri]$_).Scheme -eq 'https'})]
    [string]
    $SasUrl,

    [Parameter(ParameterSetName="localBuildByName")]
    [Parameter(ParameterSetName="localBuildAll")]
    [Parameter(Mandatory, ParameterSetName="TestByName")]
    [Parameter(Mandatory, ParameterSetName="TestAll")]
    [Parameter(Mandatory, ParameterSetName="GetTagsByName")]
    [Parameter(Mandatory, ParameterSetName="GetTagsAll")]
    [ValidatePattern('(\d+\.){2}\d(-\w+(\.\d+)?)?')]
    [string]
    $Version,

    [Parameter(ParameterSetName="GenerateTagsYaml")]
    [ValidatePattern('(\d+\.){2}\d(-\w+(\.\d+)?)?')]
    [string]
    $StableVersion,

    [Parameter(ParameterSetName="GenerateTagsYaml")]
    [ValidatePattern('(\d+\.){2}\d(-\w+(\.\d+)?)?')]
    [string]
    $PreviewVersion,

    [Parameter(ParameterSetName="GenerateTagsYaml")]
    [ValidatePattern('(\d+\.){2}\d(-\w+(\.\d+)?)?')]
    [string]
    $ServicingVersion,

    [switch]
    $IncludeKnownIssues
)

DynamicParam {
    # Add a dynamic parameter '-Name' which specifies the name(s) of the images to build or test
    $buildHelperPath = Join-Path -Path $PSScriptRoot -ChildPath 'tools/buildHelper'

    Import-Module $buildHelperPath -Force


    # Get the names of the builds.
    $releasePath = Join-Path -Path $PSScriptRoot -ChildPath 'release'

    switch ($Channel)
    {
        $null {
            $imageChannel = 'all'
        }

        default {
            $imageChannels = $Channel
        }
    }

    $dockerFileNames = @()
    foreach($imageChannel in $imageChannels){
        Get-ImageList -Channel $imageChannel | ForEach-Object { $dockerFileNames += $_ }
    }

    # Create the parameter attributs
    $Attributes = New-Object "System.Collections.ObjectModel.Collection``1[System.Attribute]"

    Add-ParameterAttribute -ParameterSetName 'TestByName' -Attributes $Attributes
    Add-ParameterAttribute -ParameterSetName 'localBuildByName' -Attributes $Attributes
    Add-ParameterAttribute -ParameterSetName 'GetTagsByName' -Attributes $Attributes

    $ValidateSetAttr = New-Object "System.Management.Automation.ValidateSetAttribute" -ArgumentList $dockerFileNames
    $Attributes.Add($ValidateSetAttr) > $null

    # Create the parameter
    $Parameter = New-Object "System.Management.Automation.RuntimeDefinedParameter" -ArgumentList ("Name", [string[]], $Attributes)

    # Return parameters dictionaly
    $Dict = New-Object "System.Management.Automation.RuntimeDefinedParameterDictionary"
    $Dict.Add("Name", $Parameter) > $null
    return $Dict
}

Begin {
    if ($PSCmdlet.ParameterSetName -notin 'GenerateTagsYaml', 'DupeCheckAll' -and $Channel.Count -gt 1)
    {
        throw "Multiple Channels are not supported in this parameter set"

        # We are using the Channel parameter, so assign the variable to that
    }

    $Channels = $Channel

    if($SasUrl)
    {
        $sasUri = [uri]$SasUrl
        $sasBase = $sasUri.GetComponents([System.UriComponents]::Path -bor [System.UriComponents]::Scheme -bor [System.UriComponents]::Host ,[System.UriFormat]::Unescaped)

        # The UriBuilder used later adds the ? even if it is already there on Windows
        # and will add it if it is not there on non-windows
        $sasQuery = $sasUri.Query -replace '^\?', ''
    }
}

End {
    $localImageNames = @()
    $testArgList = @()
    $tagGroups = @{}
    $dupeCheckTable = @{}
    $dupeTagIssues = @()

    foreach ($actualChannel in $Channels) {
        if ($PSCmdlet.ParameterSetName -match '.*ByName')
        {
            # We are using the Name parameter, so assign the variable to that
            $Name = $PSBoundParameters['Name']
        }
        else
        {
            # We are using all, so get the list off all images for the current channel
            $Name = Get-ImageList -Channel $actualChannel
        }

        $versionExtraParams = @{
            ServicingVersion = if($Version) {$Version} else {$ServicingVersion}
            PreviewVersion = if($Version) {$Version} else {$PreviewVersion}
            StableVersion = if($Version) {$Version} else {$StableVersion}
        }

        # Get Versions
        $versions = Get-Versions -Channel $actualChannel @versionExtraParams
        $windowsVersion = $versions.windowsVersion
        $linuxVersion = $versions.linuxVersion

        # Calculate the paths
        $channelPath = Join-Path -Path $releasePath -ChildPath $actualChannel.ToLowerInvariant()

        foreach($dockerFileName in $Name)
        {
            # Get all image meta data
            $allMeta = Get-DockerImageMetaDataWrapper `
                -DockerFileName $dockerFileName `
                -CI:$CI.IsPresent `
                -IncludeKnownIssues:$IncludeKnownIssues.IsPresent `
                -ChannelPath $channelPath `
                -TagFilter $TagFilter

            $meta = $allMeta.meta
            $tagsTemplates = $allMeta.tagsTemplates
            $imagePath = $allMeta.imagePath
            $tagData = $allMeta.tagData

            $psversion = $windowsVersion
            if($meta.ShouldUseLinuxVersion())
            {
                $psversion = $linuxVersion
            }

            foreach ($tagGroup in ($tagData | Group-Object -Property 'FromTag')) {
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
                        $actualVersion = $windowsVersion
                        $actualTag = $actualTag -replace '#psversion#', $actualVersion
                        $actualTag = $actualTag.ToLowerInvariant()
                        $actualTags += "${ImageName}:$actualTag"
                        $tagList += $actualTag
                        $fromTag = $Tag.FromTag
                    }
                }

                $firstActualTag = $actualTags[0]
                $firstActualTagOnly = $tagList[0]

                if ($Build.IsPresent -or $Test.IsPresent)
                {
                    Write-Verbose -Message "Adding the following to the list to be tested, fromTag: $fromTag Tag: $actualTag PSversion: $psversion" -Verbose
                    $contextPath = Join-Path -Path $imagePath -ChildPath 'docker'
                    $vcf_ref = git rev-parse --short HEAD
                    $script:ErrorActionPreference = 'stop'
                    $testsPath = Join-Path -Path $PSScriptRoot -ChildPath 'tests'
                    Import-Module (Join-Path -Path $testsPath -ChildPath 'containerTestCommon.psm1') -Force
                    if ($meta.IsLinux) {
                        $os = 'linux'
                    }
                    else {
                        $os = 'windows'
                    }

                    $skipVerification = $false
                    if($dockerFileName -eq 'nanoserver' -and $CI.IsPresent)
                    {
                        Write-Verbose -Message "Skipping verification of $firstActualTagOnly in CI because the CI system only supports LTSC and at least 1709 is required." -Verbose
                        # The version of nanoserver in CI doesn't have all the changes needed to verify the image
                        $skipVerification = $true
                    }

                    # for the image name label, always use the official image name
                    $imageNameParam = 'mcr.microsoft.com/powershell:' + $firstActualTagOnly
                    if($actualChannel -like 'community-*')
                    {
                        # use the image name for pshorg for community images
                        $imageNameParam = 'pshorg/powershellcommunity:' + $firstActualTagOnly
                    }

                    $packageVersion = $psversion

                    # if the package name ends with rpm
                    # then replace the - in the filename with _ as fpm creates the packages this way.
                    if($meta.PackageFormat -match 'rpm$')
                    {
                        $packageVersion = $packageVersion -replace '-', '_'
                    }

                    $buildArgs =  @{
                            fromTag = $fromTag
                            PS_VERSION = $psVersion
                            PACKAGE_VERSION = $packageVersion
                            VCS_REF = $vcf_ref
                            IMAGE_NAME = $imageNameParam
                        }

                    if($SasUrl)
                    {
                        $packageUrl = [System.UriBuilder]::new($sasBase)

                        $previewTag = ''
                        if($actualChannel -like '*preview*')
                        {
                            $previewTag = '-preview'
                        }

                        $packageName = $meta.PackageFormat -replace '\${PS_VERSION}', $packageVersion
                        $packageName = $packageName -replace '\${previewTag}', $previewTag
                        $containerName = 'v' + ($psversion -replace '\.', '-') -replace '~', '-'
                        $packageUrl.Path = $packageUrl.Path + $containerName + '/' + $packageName
                        $packageUrl.Query = $sasQuery
                        if($meta.Base64EncodePackageUrl)
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
                        https://github.com/PowerShell/PowerShell/releases/download/v6.1.3/powershell-6.1.3-1.rhel.7.x86_64.rpm
                        $packageUrl = [System.UriBuilder]::new('https://github.com/PowerShell/PowerShell/releases/download/')
                        $packageName = $meta.PackageFormat -replace '\${PS_VERSION}', $packageVersion
                        $packageName = $packageName -replace '\${previewTag}', $previewTag
                        $containerName = 'v' + ($psversion -replace '~', '-')
                        $packageUrl.Path = $packageUrl.Path + $containerName + '/' + $packageName
                        $buildArgs.Add('PS_PACKAGE_URL', $packageUrl.ToString())
                    }

                    $testArgs = @{
                        tags = $actualTags
                        BuildArgs = $buildArgs
                        ContextPath = $contextPath
                        OS = $os
                        ExpectedVersion = $actualVersion
                        SkipVerification = $skipVerification
                        SkipWebCmdletTests = $meta.SkipWebCmdletTests
                        SkipGssNtlmSspTests = $meta.SkipGssNtlmSspTests
                    }

                    $testArgList += $testArgs
                    $localImageNames += $firstActualTag
                }
                elseif ($GetTags.IsPresent) {
                    Write-Verbose "from: $fromTag actual: $($actualTags -join ', ') psversion: $psversion" -Verbose
                }
                elseif ($CheckForDuplicateTags.IsPresent) {
                    Write-Verbose "$actualChannel - from: $fromTag actual: $($actualTags -join ', ') psversion: $psversion" -Verbose
                    foreach($tag in $actualTags)
                    {
                        if($dupeCheckTable.ContainsKey($tag))
                        {
                            $dupeTagIssues += "$tag is duplicate for both '$actualChannel/$dockerFileName' and '$($dupeCheckTable.$tag)'"
                        }
                        else
                        {
                            $dupeCheckTable.Add($tag,"$actualChannel/$dockerFileName")
                        }
                    }
                }
                elseif ($GenerateTagsYaml.IsPresent) {
                    $tagGroup = 'public/powershell'
                    $os = 'windows'
                    if($meta.IsLinux)
                    {
                        $os = 'linux'
                    }
                    $architecture = 'amd64'
                    $dockerfile = "https://github.com/PowerShell/PowerShell-Docker/blob/master/release/$actualChannel/$dockerFileName/docker/Dockerfile"

                    $osVersion = $meta.osVersion
                    if($osVersion)
                    {
                        $osVersion = $osVersion.replace('${fromTag}',$fromTag)

                        if(!$tagGroups.ContainsKey($tagGroup))
                        {
                            $tags = @()
                            $tagGroups[$tagGroup] = $tags
                        }
                        $tag = [PSCustomObject]@{
                            Architecture = $architecture
                            OsVersion = $osVersion
                            Os = $os
                            Tags = $tagList
                            Dockerfile = $dockerfile
                        }

                        $tagGroups[$tagGroup] += $tag
                    }
                    else {
                        Write-Verbose "Skipping $firstActualTagOnly due to no OS Version in meta.json" -Verbose
                    }
                }
            }
        }
    }

    if($testArgList.Count -gt 0)
    {
        $logPath = Join-Path -Path $PSScriptRoot -ChildPath "testResults$TestLogPostfix.xml"
        $testArgPath = Join-Path -Path $testsPath -ChildPath 'testArgs.json'
        $testArgList | ConvertTo-Json -Depth 2 | Out-File -FilePath $testArgPath
        $testArgList += $testArgs
        Write-Verbose "Launching pester..." -Verbose
        $extraParams = @{}
        if($Test.IsPresent)
        {
            $tags = @('Behavior')
            if($Pull.IsPresent)
            {
                $tags += 'Pull'
            }

            $extraParams.Add('Tags',$tags)
        }
        else {
            $tags = @('Build')
            if(!$SkipTest.IsPresent)
            {
                $tags += 'Behavior'
            }

            if($Pull.IsPresent)
            {
                $tags += 'Pull'
            }

            if($Push.IsPresent)
            {
                $tags += 'Push'
            }

            $extraParams.Add('Tags', $tags)
        }

        Write-Verbose -Message "logging to $logPath" -Verbose
        $results = Invoke-Pester -Script $testsPath -OutputFile $logPath -PassThru -OutputFormat NUnitXml @extraParams
        if(!$results -or $results.FailedCount -gt 0 -or !$results.PassedCount)
        {
            throw "Build or tests failed.  Passed: $($results.PassedCount) Failed: $($results.FailedCount)"
        }
    }

    # print local image names
    # used only with the -Build
    foreach($fullName in $localImageNames)
    {
        Write-Verbose "image name: $fullName" -Verbose
    }

    if($GenerateTagsYaml.IsPresent)
    {
        Write-Output "repos:"
        foreach($repo in $tagGroups.Keys)
        {
            Write-Output "  - repoName: $repo"
            Write-Output "    tagGroups:"
            foreach($tag in $tagGroups.$repo)
            {
                Write-Output "    - tags: [$($tag.Tags -join ', ')]"
                Write-Output "      osVersion: $($tag.osVersion)"
                Write-Output "      architecture: $($tag.architecture)"
                Write-Output "      os: $($tag.os)"
                Write-Output "      dockerfile: $($tag.dockerfile)"
            }
        }
    }

    if($CheckForDuplicateTags.IsPresent)
    {
        if($dupeTagIssues.count -gt 0)
        {
            throw ($dupeTagIssues -join [System.Environment]::NewLine)
        }
        else
        {
            Write-Verbose "No duplicates found." -Verbose
        }
    }
}
