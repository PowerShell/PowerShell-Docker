param(
    [Parameter(Mandatory)]
    [string]
    $Name,
    [Parameter(Mandatory)]
    [int]
    $BuildDefinitionId,
    [Parameter(Mandatory)]
    [ValidateSet('public','internal')]
    [string]
    $Namespace
)


$releasePath = Join-Path -Path $PSScriptRoot -ChildPath 'release'
$imagePath = Join-Path -Path $releasePath -ChildPath $Name
$scriptPath = Join-Path -Path $imagePath -ChildPath 'getLatestTag.ps1'
$tagsJsonPath = Join-Path -Path $imagePath -ChildPath 'tags.json'
$psversionsJsonPath = Join-Path -Path $imagePath -ChildPath 'psVersions.json'
$tagsTemplates = Get-Content -Path $tagsJsonPath | ConvertFrom-Json
$psVersions = Get-Content -Path $psversionsJsonPath | ConvertFrom-Json

$tagData = & $scriptPath

$headers = @{  Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"  }
$baseUrl = "{0}{1}" -f $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI, $env:SYSTEM_TEAMPROJECTID
$buildsUrl = [string]::Format("{0}/_apis/build/builds?api-version=2.0", $baseUrl)
Write-Verbose "url: $buildsUrl"

if (!$ShortTag) {
    foreach ($psversion in $psVersions) {
        foreach ($tag in $tagData) {
            foreach ($tagTemplate in $tagsTemplates) {
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
                    Write-Verbose -Message "Skipping $($tag.Tag) - $tagTemplate" -Verbose
                    continue
                }
                
                $actualTag = $actualTag -replace '#psversion#', $psversion
                $fromTag = $Tag.FromTag
                Write-Verbose -Message "lauching build with fromTag: $fromTag Tag: $actualTag PSversion: $psversion" -Verbose
                $parameters = @{
                    fromTag = $fromTag
                    imageTag = $actualTag
                    PowerShellVersion = $psversion
                    Namespace = $Namespace.ToLowerInvariant()
                }
                $parametersJson = $parameters | ConvertTo-Json
                Write-Verbose -Message "paramJson: $parametersJson"
                $restBody = @{
                    definition = @{
                        id           = $BuildDefinitionId
                    }
                    sourceBranch = $env:BUILD_SOURCEBRANCH
                    parameters   = $parametersJson
                }
                $restBodyJson = ConvertTo-Json $restBody
                Write-Verbose -Message "restBody: $restBodyJson"

                $restResult = Invoke-RestMethod -Method Post -ContentType application/json -Uri $buildsUrl -Body $restBodyJson -Headers $headers
            }
        }
    }
}