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

    [ValidateSet('stable','preview','servicing','community-stable','community-preview','community-servicing')]
    [Parameter(Mandatory)]
    [string]
    $Channel='stable',

    [Parameter(ParameterSetName="localBuildByName")]
    [Parameter(ParameterSetName="localBuildAll")]
    [ValidateScript({([uri]$_).Scheme -eq 'https'})]
    [string]
    $SasUrl,

    [Parameter(ParameterSetName="localBuildByName")]
    [Parameter(ParameterSetName="localBuildAll")]
    [ValidatePattern('(\d+\.){2}\d(-\w+(\.\d+)?)?')]
    [string]
    $Version
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
            $imageChannel = $Channel
        }
    }

    $dockerFileNames = @()
    Get-ImageList -Channel $imageChannel | ForEach-Object { $dockerFileNames += $_ }

    # Create the parameter attributs
    $Attributes = New-Object "System.Collections.ObjectModel.Collection``1[System.Attribute]"

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

    Add-ParameterAttribute -ParameterSetName 'TestByName' -Attributes $Attributes
    Add-ParameterAttribute -ParameterSetName 'localBuildByName' -Attributes $Attributes
    Add-ParameterAttribute -ParameterSetName 'GetTagsByName' -Attributes $Attributes

    $ValidateSetAttr = New-Object "System.Management.Automation.ValidateSetAttribute" -ArgumentList $dockerFileNames
    $Attributes.Add($ValidateSetAttr) > $null

    # Create the parameter
    $Parameter = New-Object "System.Management.Automation.RuntimeDefinedParameter" -ArgumentList ("Name", [string[]], $Attributes)
    $Dict = New-Object "System.Management.Automation.RuntimeDefinedParameterDictionary"
    $Dict.Add("Name", $Parameter) > $null
    return $Dict
}

Begin {
    $versionExtraParams = @{}
    if($Version){
        $versionExtraParams.Add('Version', $Version)
    }

    switch -RegEx ($Channel)
    {
        'servicing$' {
            $windowsVersion = Get-PowerShellVersion -Servicing @versionExtraParams
            $linuxVersion = Get-PowerShellVersion -Linux -Servicing @versionExtraParams
        }
        'preview$' {
            $windowsVersion = Get-PowerShellVersion -Preview @versionExtraParams
            $linuxVersion = Get-PowerShellVersion -Linux -Preview @versionExtraParams
        }
        'stable$' {
            $windowsVersion = Get-PowerShellVersion @versionExtraParams
            $linuxVersion = Get-PowerShellVersion -Linux @versionExtraParams
        }
        default {
            throw "unknown channel: $Channel"
        }
    }

    if ($PSCmdlet.ParameterSetName -match '.*ByName')
    {
        # We are using the Name parameter, so assign the variable to that
        $Name = $PSBoundParameters['Name']
    }
    else
    {
        # We are using all, so get the list off all images for the current channel
        $Name = Get-ImageList -Channel $Channel
    }

    if($SasUrl)
    {
        $sasUri = [uri]$SasUrl
        $sasBase = $sasUri.GetComponents([System.UriComponents]::Path -bor [System.UriComponents]::Scheme -bor [System.UriComponents]::Host ,[System.UriFormat]::Unescaped)
        $sasQuery = $sasUri.Query
    }
}

End {

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

    # Calculate the paths
    $channelPath = Join-Path -Path $releasePath -ChildPath $Channel.ToLowerInvariant()

    $localImageNames = @()
    $testArgList = @()

    foreach($dockerFileName in $Name)
    {
        $imagePath = Join-Path -Path $channelPath -ChildPath $dockerFileName
        $scriptPath = Join-Path -Path $imagePath -ChildPath 'getLatestTag.ps1'
        $tagsJsonPath = Join-Path -Path $imagePath -ChildPath 'tags.json'
        $metaJsonPath = Join-Path -Path $imagePath -ChildPath 'meta.json'

        # skip an image if it doesn't exist
        if(!(Test-Path $scriptPath))
        {
            Write-Warning "Channel: $Channel, Name: $dockerFileName does not existing.  Not every image exists in every channel.  Skipping."
            continue
        }

        $tagsTemplates = Get-Content -Path $tagsJsonPath | ConvertFrom-Json
        $meta = Get-DockerImageMetaData -Path $metaJsonPath

        $psversion = $windowsVersion
        if($meta.ShouldUseLinuxVersion())
        {
            $psversion = $linuxVersion
        }

        # Get the tag data for the image
        $tagData = & $scriptPath -CI:$CI.IsPresent

        if (!$ShortTag) {
            foreach ($tagGroup in ($tagData | Group-Object -Property 'FromTag')) {
                $actualTags = @()
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
                            Write-Verbose -Message "Skipping $($tag.Tag) - $tagTemplate" -Verbose
                            continue
                        }

                        # Replace the the psversion token with the powershell version in the tag
                        $actualVersion = $windowsVersion
                        $actualTag = $actualTag -replace '#psversion#', $actualVersion
                        $actualTag = $actualTag.ToLowerInvariant()
                        $actualTags += "${ImageName}:$actualTag"
                        $fromTag = $Tag.FromTag
                    }
                }


                if ($Build.IsPresent -or $Test.IsPresent) {
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

                    $firstActualTag = $actualTags[0]
                    $skipVerification = $false
                    if($dockerFileName -eq 'nanoserver' -and $CI.IsPresent)
                    {
                        Write-Verbose -Message "Skipping verification of $firstActualTag in CI because the CI system only supports LTSC and at least 1709 is required." -Verbose
                        # The version of nanoserver in CI doesn't have all the changes needed to verify the image
                        $skipVerification = $true
                    }

                    # for the image name label, always use the official image name
                    $imageNameParam = 'mcr.microsoft.com/powershell:' + ($firstActualTag -split ':')[1]
                    if($Channel -like 'community-*')
                    {
                        # use the image name for pshorg for community images
                        $imageNameParam = 'pshorg/powershellcommunity:' + ($firstActualTag -split ':')[1]
                    }

                    $buildArgs =  @{
                        fromTag = $fromTag
                        PS_VERSION = $psversion
                        VCS_REF = $vcf_ref
                        IMAGE_NAME = $imageNameParam
                    }

                    if($SasUrl)
                    {
                        $packageUrl = [System.UriBuilder]::new($sasBase)
                        $packageVersion = $psversion

                        # if the package name ends with rpm
                        # then replace the - in the filename with _ as fpm creates the packages this way.
                        if($meta.PackageFormat -match 'rpm$')
                        {
                            $packageVersion = $packageVersion -replace '-', '_'
                        }

                        $packageName = $meta.PackageFormat -replace '\${PS_VERSION}', $packageVersion
                        $containerName = 'v' + ($psversion -replace '\.', '-') -replace '~', '-'
                        $packageUrl.Path = $packageUrl.Path + $containerName + '/' + $packageName
                        $packageUrl.Query = $sasQuery
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
                    }

                    $testArgList += $testArgs
                    $localImageNames += $firstActualTag
                }
                elseif ($GetTags.IsPresent) {
                    Write-Verbose "from: $fromTag actual: $($actualTags -join ', ') psversion: $psversion" -Verbose
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
}
