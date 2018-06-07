# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# return objects representing the tags we need to base the trusty image on

# The versions of trusty we care about
$shortTags = @('trusty')
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# return objects representing the tags we need to base the trusty image on

# The versions of trusty we care about
$shortTags = @('trusty')

$parent = Join-Path -Path $PSScriptRoot -ChildPath '..'
$repoRoot = Join-Path -Path $parent -ChildPath '..'
$modulePath = Join-Path -Path $repoRoot -ChildPath 'tools\getDockerTags'
Import-Module $modulePath

Get-DockerTags -ShortTags $shortTags -Image "ubuntu" -FullTagFilter 'trusty-\d{8}[\.\d{1}]?' -AlternativeShortTag '14.04'
