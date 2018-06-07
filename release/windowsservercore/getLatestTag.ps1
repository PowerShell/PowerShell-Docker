# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# return objects representing the tags we need to base the nanoserver image on

param(
    [Switch]
    $CI
)

$parent = Join-Path -Path $PSScriptRoot -ChildPath '..'
$repoRoot = Join-Path -Path $parent -ChildPath '..'
$modulePath = Join-Path -Path $repoRoot -ChildPath 'tools\getDockerTags'
Import-Module $modulePath -Force

if(!$CI.IsPresent)
{
    # The versions of nanoserver we care about
    $shortTags = @('1709','1803')

    Get-DockerTags -ShortTags $shortTags -Image "microsoft/windowsservercore" -FullTagFilter '\d{4}_KB\d{7}'
}

$shortTags = @('latest')

Get-DockerTags -ShortTags $shortTags -Image "microsoft/windowsservercore" -FullTagFilter '10\.0\.14393\.\d*$' -AlternativeShortTag 'ltsc2016' -SkipShortTagFilter