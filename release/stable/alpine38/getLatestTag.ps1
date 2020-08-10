# Copyright (c) Microsoft Corporation. 
# Licensed under the MIT License.

# return objects representing the tags we need to base the Alpine image on

# The versions of Alpine we care about, for this dockerfile
$shortTags = @('3.8')

$parent = Join-Path -Path $PSScriptRoot -ChildPath '..'
$repoRoot = Join-Path -path (Join-Path -Path $parent -ChildPath '..') -ChildPath '..'
$modulePath = Join-Path -Path $repoRoot -ChildPath 'tools\getDockerTags'
Import-Module $modulePath

Get-DockerTags -ShortTags $shortTags -Image "alpine" -FullTagFilter '^3.\d$' -OnlyShortTags
