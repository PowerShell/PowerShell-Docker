# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# return objects representing the tags we need to base the nanoserver image on

$parent = Join-Path -Path $PSScriptRoot -ChildPath '..'
$repoRoot = Join-Path -Path $parent -ChildPath '..'
$modulePath = Join-Path -Path $repoRoot -ChildPath 'tools\getDockerTags'
Import-Module $modulePath

# The versions of nanoserver we care about
$shortTags = @('1709','1803')

Get-DockerTags -ShortTags $shortTags -Image "microsoft/nanoserver" -FullTagFilter '\d{4}_KB\d{7}'
