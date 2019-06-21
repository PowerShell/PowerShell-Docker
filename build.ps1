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
    $ImageName = 'ps.local',

    [string]
    $Repository = 'powershell',

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
    $Attributes = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

    Add-ParameterAttribute -ParameterSetName 'TestByName' -Attributes $Attributes
    Add-ParameterAttribute -ParameterSetName 'localBuildByName' -Attributes $Attributes
    Add-ParameterAttribute -ParameterSetName 'GetTagsByName' -Attributes $Attributes

    if($dockerFileNames.Count -gt 0)
    {
        $ValidateSetAttr = [System.Management.Automation.ValidateSetAttribute]::new(([string[]]$dockerFileNames))
        $Attributes.Add($ValidateSetAttr) > $null
    }

    # Create the parameter
    $Parameter = [System.Management.Automation.RuntimeDefinedParameter]::new("Name", [string[]], $Attributes)

    # Return parameters dictionaly
    $parameters = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
    $parameters.Add("Name", $Parameter) > $null
    return $parameters
}

Begin {
    if ($PSCmdlet.ParameterSetName -notin 'GenerateTagsYaml', 'DupeCheckAll' -and $Channel.Count -gt 1)
    {
        throw "Multiple Channels are not supported in this parameter set"

        # We are using the Channel parameter, so assign the variable to that
    }

    $Channels = $Channel

    $sasData = $null
    if($SasUrl)
    {
        $sasData = New-SasData -SasUrl $SasUrl
    }
}

End {
    Set-StrictMode -Version latest
    $localImageNames = @()
    $testArgList = @()
    $tagGroups = @{}
    $dupeCheckTable = @{}
    $dupeTagIssues = @()

    $toBuild = @()
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
                -TagFilter $TagFilter `
                -Version $windowsVersion `
                -ImageName $ImageName `
                -LinuxVersion $linuxVersion `
                -BaseRepositry $Repository `
                -Strict:$CheckForDuplicateTags.IsPresent

            $nameForMessage = Split-Path -Leaf -Path $dockerFileName
            $message = "Channel: $nameForMessage does not exist.  Not every image exists in every channel.  Skipping."
            if(!$allMeta)
            {
                if($CI.IsPresent -and !$GetTags.IsPresent)
                {
                    Write-Warning $message
                    throw $message
                }
                else
                {
                    Write-Warning $message
                }
            }
            else
            {

                $toBuild += $allMeta
                if($allMeta.Meta.SubImage)
                {
                    foreach ($tagGroup in $allMeta.ActualTagDataByGroup.Keys)
                    {
                        $actualTagData = $allMeta.ActualTagDataByGroup.$tagGroup
                        Write-Verbose -Message "getting subimage - fromtag: $($tagGroup.Name) - subimage: $($allMeta.Meta.SubImage)"
                        $SubImagePath = Join-Path -Path $dockerFileName -ChildPath $allMeta.Meta.SubImage

                        $subImageAllMeta = Get-DockerImageMetaDataWrapper `
                            -DockerFileName $SubImagePath `
                            -CI:$CI.IsPresent `
                            -IncludeKnownIssues:$IncludeKnownIssues.IsPresent `
                            -ChannelPath $channelPath `
                            -TagFilter $TagFilter `
                            -Version $windowsVersion `
                            -ImageName $ImageName `
                            -LinuxVersion $linuxVersion `
                            -TagData $allMeta.TagData `
                            -BaseImage $actualTagData.ActualTags[0] `
                            -BaseRepositry $Repository `
                            -Strict:$CheckForDuplicateTags.IsPresent


                        $toBuild += $subImageAllMeta
                    }
                }
            }
        }
    }

    foreach($allMeta in $toBuild)
    {
        foreach ($tagGroup in $allMeta.ActualTagDataByGroup.Keys)
        {
            $actualTagData = $allMeta.ActualTagDataByGroup.$tagGroup

            if ($Build.IsPresent -or $Test.IsPresent)
            {
                $params = @{
                    Dockerfile=$dockerFileName
                    psversion=$allMeta.psversion
                    SasData= $sasData
                    actualChannel= $actualChannel
                    actualTagData= $actualTagData
                    actualVersion= $windowsVersion
                    AllMeta= $allMeta
                    CI=$CI.IsPresent
                }

                if($allMeta.BaseImage)
                {
                    $params.Add('BaseImage',$allMeta.BaseImage)
                }

                $testParams = Get-TestParams @params

                $testArgList += $testParams.TestArgs
                $localImageNames += $testParams.ImageName
            }
            elseif ($GetTags.IsPresent) {
                Write-Verbose "from: $($actualTagData.fromTag) actual: $($actualTagData.actualTags -join ', ') psversion: $($allMeta.psversion)" -Verbose
            }
            elseif ($CheckForDuplicateTags.IsPresent) {
                Write-Verbose "$actualChannel - from: $($actualTagData.fromTag) actual: $($actualTagData.actualTags -join ', ') psversion: $($allMeta.psversion)" -Verbose
                foreach($tag in $actualTagData.actualTags)
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
                $tagGroup = "public/$($allMeta.FullRepository)"
                $os = 'windows'
                if($allMeta.meta.IsLinux)
                {
                    $os = 'linux'
                }
                $architecture = 'amd64'
                $imagePath = $allMeta.imagePath
                $relativeImagePath = $imagePath -replace $PSScriptRoot
                $relativeImagePath = $relativeImagePath -replace '\\', '/'
                $dockerfile = "https://github.com/PowerShell/PowerShell-Docker/blob/master$relativeImagePath/docker/Dockerfile"

                $osVersion = $allMeta.meta.osVersion
                if($osVersion)
                {
                    $osVersion = $osVersion.replace('${fromTag}',$actualTagData.fromTag)

                    if(!$tagGroups.ContainsKey($tagGroup))
                    {
                        $tags = @()
                        $tagGroups[$tagGroup] = $tags
                    }

                    $tag = [PSCustomObject]@{
                        Architecture = $architecture
                        OsVersion = $osVersion
                        Os = $os
                        Tags = $actualTagData.TagList
                        Dockerfile = $dockerfile
                    }

                    $tagGroups[$tagGroup] += $tag
                }
                else {
                    Write-Verbose "Skipping $($actualTagData.tagList[0]) due to no OS Version in meta.json" -Verbose
                }
            }
        }
    }


    if($testArgList.Count -gt 0)
    {
        $logPath = Join-Path -Path $PSScriptRoot -ChildPath "testResults$TestLogPostfix.xml"
        $testsPath = Join-Path -Path $PSScriptRoot -ChildPath 'tests'
        $testArgPath = Join-Path -Path $testsPath -ChildPath 'testArgs.json'
        $testArgList | ConvertTo-Json -Depth 2 | Out-File -FilePath $testArgPath

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
