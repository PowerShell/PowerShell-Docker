# Copyright (c) Microsoft Corporation. 
# Licensed under the MIT License.

# return objects representing the tags we need to base the debian image on Docker

# The versions of debian we care about
$shortTags = @('buster-slim')

$parent = Join-Path -Path $PSScriptRoot -ChildPath '..'
$repoRoot = Join-Path -path (Join-Path -Path $parent -ChildPath '..') -ChildPath '..'
$modulePath = Join-Path -Path $repoRoot -ChildPath 'tools\getDockerTags'
Import-Module $modulePath

Get-DockerTags -ShortTags $shortTags -Image "debian" -FullTagFilter 'buster-\d{8}[\.\d{1}]?-slim' -AlternativeShortTag '10' -SkipShortTagFilter
