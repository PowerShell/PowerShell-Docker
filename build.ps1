#!/usr/bin/pwsh
# Copyright (c) Microsoft Corporation.
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

    [Parameter(Mandatory, ParameterSetName="GenerateMatrixJson")]
    [switch]
    $GenerateMatrixJson,

    [Parameter(ParameterSetName="GenerateMatrixJson")]
    [switch]
    $FullJson,

    [Parameter(Mandatory, ParameterSetName="GenerateManifestLists")]
    [switch]
    $GenerateManifestLists,

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

    [ValidateSet('stable','preview','servicing','community-stable','community-preview','community-servicing','lts')]
    [Parameter(Mandatory, ParameterSetName="TestByName")]
    [Parameter(Mandatory, ParameterSetName="TestAll")]
    [Parameter(ParameterSetName="localBuildByName")]
    [Parameter(Mandatory, ParameterSetName="localBuildAll")]
    [Parameter(Mandatory, ParameterSetName="GetTagsByName")]
    [Parameter(Mandatory, ParameterSetName="GetTagsAll")]
    [Parameter(Mandatory, ParameterSetName="DupeCheckAll")]
    [Parameter(Mandatory, ParameterSetName="GenerateTagsYaml")]
    [Parameter(Mandatory, ParameterSetName="GenerateMatrixJson")]
    [Parameter(Mandatory, ParameterSetName="GenerateManifestLists")]
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

    [Parameter(ParameterSetName="GenerateMatrixJson")]
    [Parameter(ParameterSetName="GenerateManifestLists")]
    [Parameter(ParameterSetName="GenerateTagsYaml")]
    [ValidatePattern('(\d+\.){2}\d(-\w+(\.\d+)?)?')]
    [string]
    $StableVersion,

    [Parameter(ParameterSetName="GenerateMatrixJson")]
    [Parameter(ParameterSetName="GenerateManifestLists")]
    [Parameter(ParameterSetName="GenerateTagsYaml")]
    [ValidatePattern('(\d+\.){2}\d(-\w+(\.\d+)?)?')]
    [string]
    $LtsVersion,

    [Parameter(ParameterSetName="GenerateManifestLists")]
    [Parameter(ParameterSetName="GenerateMatrixJson")]
    [Parameter(ParameterSetName="GenerateTagsYaml")]
    [ValidatePattern('(\d+\.){2}\d(-\w+(\.\d+)?)?')]
    [string]
    $PreviewVersion,

    [Parameter(ParameterSetName="GenerateManifestLists")]
    [Parameter(ParameterSetName="GenerateMatrixJson")]
    [Parameter(ParameterSetName="GenerateTagsYaml")]
    [ValidatePattern('(\d+\.){2}\d(-\w+(\.\d+)?)?')]
    [string]
    $ServicingVersion,

    [Parameter(ParameterSetName="GenerateTagsYaml")]
    [ValidateSet('YAML','JSON')]
    [string]
    $Format = 'YAML',

    [switch]
    $IncludeKnownIssues,

    [switch]
    $ForcePesterInstall,

    [Parameter(ParameterSetName="GenerateManifestLists")]
    [Parameter(ParameterSetName="GenerateMatrixJson")]
    [string]
    [ValidateSet('All','OnlyAcr','NoAcr')]
    $Acr,

    [Parameter(ParameterSetName="GenerateManifestLists")]
    [Parameter(ParameterSetName="GenerateMatrixJson")]
    [string]
    [ValidateSet('All','Linux','Windows')]
    $OsFilter

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
    Add-ParameterAttribute -ParameterSetName 'GenerateTagsYaml' -Attributes $Attributes -Mandatory $false

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
    $ENV:DOCKER_BUILDKIT=1
    if ($PSCmdlet.ParameterSetName -notin 'GenerateMatrixJson', 'GenerateTagsYaml', 'DupeCheckAll', 'GenerateManifestLists' -and $Channel.Count -gt 1)
    {
        throw "Multiple Channels are not supported in this parameter set"
    }

    # We are using the Channel parameter, so assign the variable to that
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
    $fullMatrix = @{}

    $toBuild = @()
    foreach ($actualChannel in $Channels) {
        if ($PSBoundParameters['Name'])
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
            LtsVersion = if($Version) {$Version} else {$LtsVersion}
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
                -BaseRepository $Repository `
                -Strict:$CheckForDuplicateTags.IsPresent `
                -Channel $actualChannel

            $nameForMessage = Split-Path -Leaf -Path $dockerFileName
            $message = "$nameForMessage does not exist in every channel. Skipping."
            if(!$allMeta)
            {
                Write-Warning $message
                if($CI.IsPresent -and !$GetTags.IsPresent)
                {
                    throw $message
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
                        $SubImagePath = Join-Path -Path $dockerFileName -ChildPath $allMeta.Meta.SubImage
                        Write-Verbose -Message "getting subimage - fromtag: $($dockerFileName) - subimage: $($allMeta.Meta.SubImage)"
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
                            -BaseRepository $Repository `
                            -Strict:$CheckForDuplicateTags.IsPresent `
                            -FromTag $tagGroup.Name `
                            -Channel $actualChannel

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
            $dockerFileName = $allMeta.Name
            $actualTagData = $allMeta.ActualTagDataByGroup.$tagGroup
            $actualChannel = $allMeta.Channel
            $useAcr = $allMeta.meta.UseAcr
            $continueOnError = $allMeta.meta.ContinueOnError

            if ($Build.IsPresent -or $Test.IsPresent)
            {
                $params = @{
                    Dockerfile    = $dockerFileName
                    psversion     = $allMeta.psversion
                    SasData       = $sasData
                    actualChannel = $actualChannel
                    actualTagData = $actualTagData
                    actualVersion = $windowsVersion
                    AllMeta       = $allMeta
                    CI            = $CI.IsPresent
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
            elseif ($GenerateTagsYaml.IsPresent -or $GenerateMatrixJson.IsPresent -or $GenerateManifestLists.IsPresent) {
                if($Acr -eq 'OnlyAcr' -and !$useAcr)
                {
                    continue
                }

                if($Acr -eq 'NoAcr' -and $useAcr)
                {
                    continue
                }

                $tagGroup = $($allMeta.FullRepository)
                $os = 'windows'
                if ($allMeta.meta.IsLinux) {
                    $os = 'linux'
                }

                if ($osFilter -eq 'Linux' -and $os -ne 'linux') {
                    continue
                }

                if ($osFilter -eq 'Windows' -and $os -ne 'windows') {
                    continue
                }

                $architecture = 'amd64'
                $imagePath = $allMeta.imagePath
                $relativeImagePath = $imagePath.Replace($PSScriptRoot,'')
                $relativeImagePath = $relativeImagePath -replace '\\', '/'
                $dockerfile = "https://github.com/PowerShell/PowerShell-Docker/blob/master$relativeImagePath/docker/Dockerfile"

                $osVersion = $allMeta.meta.osVersion
                $manifestLists = $allMeta.meta.ManifestLists
                if($osVersion -or $GenerateMatrixJson.IsPresent -or $GenerateManifestLists.IsPresent)
                {
                    if ($osVersion) {
                        $osVersion = $osVersion.replace('${fromTag}', $actualTagData.fromTag)
                    }
                    else {
                        throw "meta.json should have osVersion: $dockerFileName"
                    }

                    # skip if we are generate TagsYaml and the image is private.
                    if (!$GenerateTagsYaml.IsPresent -or !$allMeta.Meta.IsPrivate) {
                        if (!$tagGroups.ContainsKey($tagGroup)) {
                            $tags = @()
                            $tagGroups[$tagGroup] = $tags
                        }

                        $tag = [PSCustomObject]@{
                            Architecture    = $architecture
                            OsVersion       = $osVersion
                            Os              = $os
                            Tags            = $actualTagData.TagList
                            Dockerfile      = $dockerfile
                            Channel         = $actualChannel
                            Name            = $dockerFileName
                            UseAcr          = $UseAcr
                            ContinueOnError = $continueOnError
                            ManifestLists   = $manifestLists
                            EndOfLife         = $allMeta.meta.EndOfLife
                            DistributionState = $allMeta.meta.GetDistributionState().ToString()
                        }

                        $tagGroups[$tagGroup] += $tag
                    }
                    else {
                        Write-Verbose -Message "skipping generating yaml for $dockerFileName" -Verbose
                    }
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

        Invoke-PesterWrapper -Script $testsPath -OutputFile $logPath -ExtraParams $extraParams
    }

    # print local image names
    # used only with the -Build
    foreach($fullName in $localImageNames)
    {
        Write-Verbose "image name: $fullName" -Verbose
    }

    if($GenerateTagsYaml.IsPresent)
    {
        if ($Format -eq 'YAML') {
            Write-Output "repos:"
            foreach($repo in $tagGroups.Keys | Sort-Object)
            {
                Write-Output "  - repoName: $repo"
                Write-Output "    tagGroups:"
                foreach($tag in $tagGroups.$repo | Sort-Object -Property dockerfile)
                {
                    Write-Output "    - tags: [$($tag.Tags -join ', ')]"
                    Write-Output "      osVersion: $($tag.osVersion)"
                    Write-Output "      architecture: $($tag.architecture)"
                    Write-Output "      os: $($tag.os)"
                    Write-Output "      dockerfile: $($tag.dockerfile)"
                }
            }
        }
        else {
            $repos = @{}
            foreach ($repo in $tagGroups.Keys | Sort-Object) {
                $tagGroupsJson = @()
                foreach ($tag in $tagGroups.$repo | Sort-Object -Property dockerfile) {
                    $tagGroupsJson += @{
                        tags         = $tag.Tags
                        osVersion    = $tag.OsVersion
                        architecture = $tag.architecture
                        os           = $tag.os
                        dockerfile   = $tag.dockerfile
                    }
                }

                $repos.Add($repo, $tagGroupsJson)
            }

            $repos | ConvertTo-Json -Depth 10
        }
    }

    if ($GenerateMatrixJson.IsPresent) {
        $matrix = @{ }
        foreach ($repo in $tagGroups.Keys | Sort-Object) {
            $channelGroups = $tagGroups.$repo | Group-Object -Property Channel
            foreach($channelGroup in $channelGroups)
            {
                $channelName = $channelGroup.Name
                Write-Verbose "generating $channelName json"
                $osGroups = $channelGroup.Group | Group-Object -Property os
                foreach ($osGroup in $osGroups) {
                    $osName = $osGroup.Name

                    # Filter out subimages.  We cannot directly build subimages.
                    foreach ($tag in $osGroup.Group | Where-Object { $_.Name -notlike '*/*' } | Sort-Object -Property dockerfile) {
                        if (-not $matrix.ContainsKey($channelName)) {
                            $matrix.Add($channelName, @{ })
                        }

                        if (-not $matrix.$channelName.ContainsKey($osName)) {
                            $matrix.$channelName.Add($osName, @{ })
                        }

                        $jobName = $tag.Name -replace '-', '_'
                        if (-not $matrix.$channelName[$osName].ContainsKey($jobName) -and -not $tag.ContinueOnError) {
                            $matrix.$channelName[$osName].Add($jobName, @{
                                    Channel           = $tag.Channel
                                    ImageName         = $tag.Name
                                    JobName           = $jobName
                                    ContinueOnError   = $tag.ContinueOnError
                                    EndOfLife         = $tag.EndOfLife
                                    DistributionState = $tag.DistributionState
                                    OsVersion         = $tag.OsVersion
                                })
                        }
                    }
                }
            }
        }

        foreach ($channelName in $matrix.Keys) {
            $fullMatrix[$channelName] = @()
            foreach ($osName in $matrix.$channelName.Keys) {
                $osMatrix = $matrix.$channelName.$osName
                $fullMatrix[$channelName] += $osMatrix.Values
                $matrixJson = $osMatrix | ConvertTo-Json -Compress
                $variableName = "matrix_${channelName}_${osName}"
                $command = "vso[task.setvariable variable=$variableName;isoutput=true]$($matrixJson)"
                if (!$FullJson) {
                    Set-Item -Path ENV:$VariableName -Value $matrixJson
                    Write-Verbose "sending command: '$command'"
                    Write-Host "##$command"
                }
            }
        }

        if($FullJson) {
            $matrixJson = $fullMatrix | ConvertTo-Json -Depth 100
            Write-Output $matrixJson
        }
    }

    if ($GenerateManifestLists.IsPresent) {
        $manifestLists = @()
        $tags = @()
        foreach ($repo in $tagGroups.Keys | Sort-Object) {
            $channelGroups = $tagGroups.$repo | Group-Object -Property Channel
            foreach ($channelGroup in $channelGroups) {
                $channelName = $channelGroup.Name
                Write-Verbose "generating $channelName json"
                $osGroups = $channelGroup.Group | Group-Object -Property os
                foreach ($osGroup in $osGroups) {
                    $osName = $osGroup.Name

                    # Filter out subimages.  We cannot directly build subimages.
                    foreach ($tag in $osGroup.Group | Where-Object { $_.Name -notlike '*/*' } | Sort-Object -Property ManifestLists) {
                        if ($tag.ManifestLists) {
                            foreach ($manifestList in $tag.ManifestLists) {

                                if ($manifestLists -notcontains $manifestList) {
                                    $manifestLists += $manifestList
                                }

                                $tag | Add-Member -MemberType NoteProperty -Value $repo -Name 'Repo'

                                $tags += $tag
                            }
                        }
                    }
                }
            }
        }

        $matrix = @{}
        foreach ($manifestList in $manifestLists) {
            $jobName = $manifestList -replace '-', '_'
            $manifestListTags = [PSCustomObject]@{
                ManifestList = $manifestList
                Channel      = ""
                Tags         = @()
                JobName      = $jobName
                Repo         = ""
            }

            foreach ($tag in $tags | Where-Object { $_.ManifestLists -contains $manifestList }) {
                if (-not $matrix.ContainsKey($manifestList)) {
                    $matrix.Add($manifestList, @{ })
                }

                $manifestListTags.Channel = $tag.Channel
                $manifestListTags.Tags += $tag.Tags | Where-Object { $_ -notmatch '\d{8}' } | Select-Object -First 1
                $manifestListTags.Repo = $tag.Repo
            }

            if (-not $matrix.$manifestList.ContainsKey($jobName) -and -not $tag.ContinueOnError) {
                $matrix.$manifestList.Add($jobName, $manifestListTags)
            }
        }

        foreach ($manifestList in $matrix.Keys) {
            foreach ($jobName in $matrix.$manifestList.Keys) {
                $jobMatrix = $matrix.$manifestList.$jobName
                $matrixJson = $jobMatrix | ConvertTo-Json -Compress
                Write-Output $matrixJson
            }
        }

        exit 0
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
