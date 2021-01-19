# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# script to create the Docker manifest lists
param (
    [ValidateNotNullOrEmpty()]
    [string]
    $Registry = 'microsoft',

    [ValidateSet('stable','preview','servicing')]
    [Parameter(Mandatory)]
    [string]
    $Channel='stable'
)

$buildScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'build.ps1'

$createScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'createManifest.ps1'

$json = &$buildScriptPath -GenerateManifestLists -Channel $Channel -OsFilter All

$manifestLists = $json | ConvertFrom-Json

$manifestLists.ManifestList | ForEach-Object {
    Write-Verbose $_ -Verbose
    $tag = $_
    $manifestList = $manifestLists | Where-Object {$_.ManifestList -eq $tag}
    $manifestList | Out-String | Write-Verbose -Verbose
    Write-Verbose -Verbose "&$createScriptPath -ContainerRegistry $Registry -taglist $manifestList.Tags -ManifestTag '$tag'"
    &$createScriptPath -ContainerRegistry $Registry -taglist $manifestList.Tags -ManifestTag $tag
}
