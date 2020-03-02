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

# The versions of nanoserver we care about
$shortTags = @('1809','1903')

Get-DockerTags -ShortTags $shortTags -Image "mcr.microsoft.com/windows/servercore" -FullTagFilter '\d{4}[-_]KB\d{7}' -Mcr
