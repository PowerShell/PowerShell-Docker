# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# return objects representing the tags we need to base the nanoserver image on


param(
    [Switch]
    $CI,
    # The versions of nanoserver we care about
    [string[]]
    $ShortTags
)

$parent = Join-Path -Path $PSScriptRoot -ChildPath '..'
$repoRoot = Join-Path -path (Join-Path -Path $parent -ChildPath '..') -ChildPath '..'
$modulePath = Join-Path -Path $repoRoot -ChildPath 'tools\getDockerTags'
Import-Module $modulePath

Get-DockerTags -ShortTags $shortTags -Image "mcr.microsoft.com/windows/nanoserver" -FullTagFilter '\d{4}[-_]KB\d{7}([\-_]amd64)?$' -Mcr

