# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Queue Docker image build for a particular image
# ** Expects to have OAuth access in the build**
# ** and the build service has to be granted permission to launch builds**
# The build is expected to have the following parameters:
#  - fromTag
#    - The tag of the image in the from statement which is being produced
#  - imageTag
#    - The tag of the produced image
#  - PowerShellVersion
#    - The version of powershell to put in the image
#  - Namespace
#    - `public` to build for public consumption.
#    - `internal` to build for internal consumption.

param(
    [Parameter(Mandatory)]
    [string]
    $Name,
    [Parameter(Mandatory)]
    [int]
    $BuildDefinitionId,
    [Parameter(Mandatory)]
    [ValidateSet('public', 'internal')]
    [string]
    $Namespace
)

&"$PSScriptRoot\build.ps1" -Name $Name -BuildDefinitionId $BuildDefinitionId -Namespace $Namespace -Vsts
