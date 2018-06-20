# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# return objects representing the tags we need to base the nanoserver image on

param(
    [Switch]
    $CI
)

$parent = Join-Path -Path $PSScriptRoot -ChildPath '..'
$repoRoot = Join-Path -path (Join-Path -Path $parent -ChildPath '..') -ChildPath '..'
$modulePath = Join-Path -Path $repoRoot -ChildPath 'tools\getDockerTags'
Import-Module $modulePath -Force

if(!$CI.IsPresent)
{
    # The versions of nanoserver we care about
    $shortTags = @('1709','1803')

    Get-DockerTags -ShortTags $shortTags -Image "microsoft/windowsservercore" -FullTagFilter '\d{4}_KB\d{7}'
}

$shortTags = @('latest')

# The \d{4,} part of the regex is because the API is returning tags which are 3 digits and older than the 4 digit tags
$fullTagFilter = '10\.0\.14393\.\d{4,}$'
if($env:APPVEYOR)
{
    # This image is already on the machine in AppVeyor, so it will be faster
    $fullTagFilter = '10\.0\.14393\.2007$'
}

Get-DockerTags -ShortTags $shortTags -Image "microsoft/windowsservercore" -FullTagFilter $fullTagFilter -AlternativeShortTag 'ltsc2016' -SkipShortTagFilter