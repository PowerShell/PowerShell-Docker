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
Import-Module $modulePath

# The versions of nanoserver we care about
$shortTags = @('1709','1803')

if(!$CI.IsPresent)
{
    Get-DockerTags -ShortTags $shortTags -Image "microsoft/nanoserver" -FullTagFilter '\d{4}_KB\d{7}'
}
else {
    # This is not supported for nanoserver so don't build in production but try building it as a CI test for the dockerfile
    $shortTags = @('latest')

    # The \d{4,} part of the regex is because the API is returning tags which are 3 digits and older than the 4 digit tags
    Get-DockerTags -ShortTags $shortTags -Image "microsoft/nanoserver" -FullTagFilter '10\.0\.14393\.\d{4,}$' -SkipShortTagFilter
}
