# Copyright (c) Microsoft Corporation. 
# Licensed under the MIT License.

# return objects representing the tags we need to base the CentOS image on Docker

# The versions of CentOS we care about
$shortTags = @('7')

$parent = Join-Path -Path $PSScriptRoot -ChildPath '..'
$repoRoot = Join-Path -path (Join-Path -Path $parent -ChildPath '..') -ChildPath '..'
$modulePath = Join-Path -Path $repoRoot -ChildPath 'tools\getDockerTags'
Import-Module $modulePath

Get-DockerTags -ShortTags $shortTags -Image "centos" -FullTagFilter '^7$' -OnlyShortTags
