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
#  - Namespace
#    - `public` to build for public consumption.
#    - `internal` to build for internal consumption.

param(
    [Parameter(Mandatory,ParameterSetName="VSTS")]
    [switch]
    $Vsts,
    [Parameter(Mandatory,ParameterSetName="localBuild")]
    [switch]
    $Build,
    [Parameter(Mandatory,ParameterSetName="GetTags")]
    [switch]
    $GetTags,
    [Parameter(Mandatory)]
    [string]
    $Name,
    [Parameter(Mandatory,ParameterSetName="VSTS")]
    [int]
    $BuildDefinitionId,
    [Parameter(Mandatory,ParameterSetName="VSTS")]
    [ValidateSet('public', 'internal')]
    [string]
    $Namespace,
    [Parameter(ParameterSetName="localBuild")]
    [string]
    $ImageName = 'powershell.local'
)

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
            $output = & $sb
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
$imagePath = Join-Path -Path $releasePath -ChildPath $Name
$scriptPath = Join-Path -Path $imagePath -ChildPath 'getLatestTag.ps1'
$tagsJsonPath = Join-Path -Path $imagePath -ChildPath 'tags.json'
$psversionsJsonPath = Join-Path -Path $imagePath -ChildPath 'psVersions.json'
$tagsTemplates = Get-Content -Path $tagsJsonPath | ConvertFrom-Json
$psVersions = Get-Content -Path $psversionsJsonPath | ConvertFrom-Json

# Get the tag data for the image
$tagData = & $scriptPath

# Create the URL and header for the REST calls
$headers = @{  Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"  }
$baseUrl = "{0}{1}" -f $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI, $env:SYSTEM_TEAMPROJECTID
$buildsUrl = [string]::Format("{0}/_apis/build/builds?api-version=2.0", $baseUrl)
Write-Verbose "url: $buildsUrl"

$localImageNames = @()

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
                $actualTag = $actualTag -replace '#psversion#', $psversion
                $actualTag = $actualTag -replace '~', '-'
                $fromTag = $Tag.FromTag

                if($Vsts.IsPresent)
                {
                    Write-Verbose -Message "lauching build with fromTag: $fromTag Tag: $actualTag PSversion: $psversion" -Verbose
                    # create the parameters object for the build
                    $parameters = @{
                        fromTag           = $fromTag
                        imageTag          = $actualTag
                        PowerShellVersion = $psversion
                        Namespace         = $Namespace.ToLowerInvariant()
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
                elseif ($Build.IsPresent) {
                    Write-Verbose -Message "building with fromTag: $fromTag Tag: $actualTag PSversion: $psversion" -Verbose
                    $contextPath = Join-Path -Path $imagePath -ChildPath 'docker'
                    $vcf_ref = git rev-parse --short HEAD
                    $fullName = "powershell.local:$actualTag"
                    Start-NativeExecution {
                        docker build -t $fullName --build-arg fromTag=$fromTag --build-arg PS_VERSION=$psversion --build-arg VCS_REF=$vcf_ref $contextPath
                    } -VerboseOutputOnError
                    $localImageNames += $fullName
                }
                elseif ($GetTags.IsPresent) {
                    Write-Verbose "from: $fromTag actual: $actualTag" -Verbose                    
                }
            }
        }
    }
}

# print local image names
# used only with the -Build
foreach($name in $localImageNames)
{
    Write-Verbose "image name: $name" -Verbose
}
