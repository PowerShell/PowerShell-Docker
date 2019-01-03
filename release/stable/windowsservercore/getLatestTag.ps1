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
    $shortTags = @('1709','1803','1809')

    Get-DockerTags -ShortTags $shortTags -Image "mcr.microsoft.com/windows/servercore" -FullTagFilter '\d{4}_KB\d{7}' -Mcr
}

$shortTags = @('latest')

# The \d{4,} part of the regex is because the API is returning tags which have been deleted, which are 3 digits
Get-DockerTags -ShortTags $shortTags -Image "mcr.microsoft.com/windows/servercore" -FullTagFilter '10\.0\.14393\.\d{4,}$' -AlternativeShortTag 'ltsc2016' -SkipShortTagFilter -Mcr
