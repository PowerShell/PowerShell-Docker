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
    [Parameter(Mandatory)]
    [string]
    $Name,
    [Parameter(Mandatory)]
    [int]
    $BuildDefinitionId,
    [Parameter(Mandatory)]
    [ValidateSet('public', 'internal')]
    [string]
    $Namespace
)

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
                $fromTag = $Tag.FromTag
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
        }
    }
}