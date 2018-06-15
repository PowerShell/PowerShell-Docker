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
    [Parameter(Mandatory,ParameterSetName="VSTS")]
    [switch]
    $Vsts,
    [Parameter(Mandatory,ParameterSetName="Test")]
    [switch]
    $Test,
    [Parameter(ParameterSetName="Test")]
    [switch]
    $Pull,
    [Parameter(Mandatory,ParameterSetName="localBuild")]
    [switch]
    $Build,
    [Parameter(Mandatory,ParameterSetName="GetTags")]
    [switch]
    $GetTags,
    [Parameter(Mandatory,ParameterSetName="VSTS")]
    [int]
    $BuildDefinitionId,
    [Parameter(Mandatory,ParameterSetName="VSTS")]
    [ValidateSet('public', 'internal')]
    [string]
    $DockerNamespace,
    [Parameter(ParameterSetName="Test")]
    [Parameter(ParameterSetName="localBuild")]
    [string]
    $ImageName = 'powershell.local',
    [Parameter(ParameterSetName="GetTags")]
    [Parameter(ParameterSetName="localBuild")]
    [switch]
    $CI,
    [ValidateSet('stable','preview')]
    [string]
    $Channel='stable'
)

DynamicParam {
    # Add a dynamic parameter '-Name' which specifies the name(s) of the images to build or test

    # Get the names of the builds.
    $releasePath = Join-Path -Path $PSScriptRoot -ChildPath 'release'
    $stablePath = Join-Path -Path $releasePath -ChildPath 'stable'
    $previewPath = Join-Path -Path $releasePath -ChildPath 'preview'

    $dockerFileNames = @()
    Get-ChildItem -Path $stablePath -Directory | Select-Object -ExpandProperty Name | ForEach-Object { $dockerFileNames += $_ }
    Get-ChildItem -Path $previewPath -Directory | Select-Object -ExpandProperty Name | Where-Object { $dockerFileNames -notcontains $_ } | ForEach-Object { $dockerFileNames += $_ }

    # Create the parameter attributs
    $ParameterAttr = New-Object "System.Management.Automation.ParameterAttribute"
    $ValidateSetAttr = New-Object "System.Management.Automation.ValidateSetAttribute" -ArgumentList $dockerFileNames
    $Attributes = New-Object "System.Collections.ObjectModel.Collection``1[System.Attribute]"
    $Attributes.Add($ParameterAttr) > $null
    $Attributes.Add($ValidateSetAttr) > $null

    # Create the parameter
    $Parameter = New-Object "System.Management.Automation.RuntimeDefinedParameter" -ArgumentList ("Name", [string[]], $Attributes)
    $Dict = New-Object "System.Management.Automation.RuntimeDefinedParameterDictionary"
    $Dict.Add("Name", $Parameter) > $null
    return $Dict
}

Begin {
    $Name = $PSBoundParameters['Name']
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
    $releasePath = Join-Path -Path $PSScriptRoot -ChildPath 'release'
    $channelPath = Join-Path -Path $releasePath -ChildPath $Channel

    # Create the URL and header for the REST calls
    $headers = @{  Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"  }
    $baseUrl = "{0}{1}" -f $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI, $env:SYSTEM_TEAMPROJECTID
    $buildsUrl = [string]::Format("{0}/_apis/build/builds?api-version=2.0", $baseUrl)
    Write-Verbose "url: $buildsUrl"

    $localImageNames = @()
    $testArgList = @()

    foreach($dockerFileName in $Name)
    {
        $imagePath = Join-Path -Path $channelPath -ChildPath $dockerFileName
        $scriptPath = Join-Path -Path $imagePath -ChildPath 'getLatestTag.ps1'
        $tagsJsonPath = Join-Path -Path $imagePath -ChildPath 'tags.json'
        $psversionsJsonPath = Join-Path -Path $imagePath -ChildPath 'psVersions.json'
        $tagsTemplates = Get-Content -Path $tagsJsonPath | ConvertFrom-Json
        $psVersions = Get-Content -Path $psversionsJsonPath | ConvertFrom-Json

        # Get the tag data for the image
        $tagData = & $scriptPath -CI:$CI.IsPresent

        if (!$ShortTag) {
            foreach ($psversion in $psVersions) {
                foreach ($tag in $tagData) {
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
                        $actualVersion = $psversion -replace '~', '-'
                        $actualTag = $actualTag -replace '#psversion#', $actualVersion
                        $actualTag = $actualTag.ToLowerInvariant()
                        $fromTag = $Tag.FromTag

                        if($Vsts.IsPresent)
                        {
                            Write-Verbose -Message "lauching build with fromTag: $fromTag Tag: $actualTag PSversion: $psversion" -Verbose
                            # create the parameters object for the build
                            $parameters = @{
                                fromTag           = $fromTag
                                imageTag          = $actualTag
                                PowerShellVersion = $psversion
                                Namespace         = $DockerNamespace.ToLowerInvariant()
                                ImageName         = $dockerFileName
                                Channel           = $Channel
                            }

                            # the rest body expects the parameters as an encoded json.
                            # So, convert to JSON before producing the body object
                            $parametersJson = $parameters | ConvertTo-Json

                            # Create the body of the request to queue the build
                            Write-Verbose -Message "paramJson: $parametersJson"
                            $restBody = @{
                                definition   = @{
                                    id = $BuildDefinitionId
                                }
                                sourceBranch = $env:BUILD_SOURCEBRANCH
                                parameters   = $parametersJson
                            }
                            $restBodyJson = ConvertTo-Json $restBody
                            Write-Verbose -Message "restBody: $restBodyJson"

                            # Queue the build
                            $null = Invoke-RestMethod -Method Post -ContentType application/json -Uri $buildsUrl -Body $restBodyJson -Headers $headers
                        }
                        elseif ($Build.IsPresent -or $Test.IsPresent) {
                            Write-Verbose -Message "Adding the following to the list to be tested, fromTag: $fromTag Tag: $actualTag PSversion: $psversion" -Verbose
                            $contextPath = Join-Path -Path $imagePath -ChildPath 'docker'
                            $vcf_ref = git rev-parse --short HEAD
                            $fullName = "${ImageName}:$actualTag"
                            $script:ErrorActionPreference = 'stop'
                            $testsPath = Join-Path -Path $PSScriptRoot -ChildPath 'tests'
                            Import-Module (Join-Path -Path $testsPath -ChildPath 'containerTestCommon.psm1') -Force
                            if($dockerFileName -iin 'windowsservercore','nanoserver')
                            {
                                $os = 'windows'
                            }
                            else {
                                $os = 'linux'
                            }
                            $skipVerification = $false
                            if($dockerFileName -eq 'nanoserver' -and $CI.IsPresent)
                            {
                                Write-Verbose -Message "Skipping verification of $fullName in CI because the CI system only supports LTSC and at least 1709 is required." -Verbose
                                # The version of nanoserver in CI doesn't have all the changes needed to verify the image
                                $skipVerification = $true
                            }

                            $testArgs = @{
                                tag = $fullName
                                BuildArgs = @{
                                    fromTag = $fromTag
                                    PS_VERSION = $psversion
                                    VCS_REF = $vcf_ref
                                }
                                ContextPath = $contextPath
                                OS = $os
                                ExpectedVersion = $actualVersion
                                SkipVerification = $skipVerification
                            }

                            $testArgList += $testArgs
                            $localImageNames += $fullName
                        }
                        elseif ($GetTags.IsPresent) {
                            Write-Verbose "from: $fromTag actual: $actualTag" -Verbose
                        }
                    }
                }
            }
        }
    }

    if($testArgList.Count -gt 0)
    {
        $logPath = Join-Path -Path $PSScriptRoot -ChildPath 'testResults.xml'
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
            $extraParams.Add('Tags',@('Build','Behavior'))
        }

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
