# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# return objects representing the tags we need to base the arch image on

# The versions of arch linux we care about
$shortTags = @('latest')

$parent = Join-Path -Path $PSScriptRoot -ChildPath '..'
$repoRoot = Join-Path -path (Join-Path -Path $parent -ChildPath '..') -ChildPath '..'
$modulePath = Join-Path -Path $repoRoot -ChildPath 'tools\getDockerTags'
Import-Module $modulePath

Get-DockerTags -ShortTags $shortTags -Image "archlinux/base" -FullTagFilter '^latest$' -OnlyShortTags
