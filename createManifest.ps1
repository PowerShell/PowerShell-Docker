# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Used to create a container manifest.
# Prereq: you must login to $ContainerRegistery before running this script
# default scenarios is to build a `latest` tag which will point to the `ubuntu-16.04` tag for linux
# and the `windowsservercore` tag for windows
param(
    [parameter(Mandatory)]
    [string]
    $ContainerRegistry,

    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[abcdefghijklmnopqrstuvwxyz\-_0123456789\.]+$')]
    [string]
    $ManifestTag = 'latest',

    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[abcdefghijklmnopqrstuvwxyz\-_0123456789\.]+$')]
    [string]
    $Image = 'powershell',

    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[abcdefghijklmnopqrstuvwxyz\-_0123456789\.]+$')]
    [string[]]
    $TagList = ('ubuntu-16.04', 'windowsservercore'),

    [switch]
    $SkipPush
)

$first = $true
$manifestList = @()
foreach($tag in $TagList)
{
    $arguments = @()
    $amend = ""
    if (!$first) {
        $arguments += '--amend'
    }
    $arguments += @(
        "$ContainerRegistry/${Image}:$ManifestTag"
        "$ContainerRegistry/${Image}:$tag"
    )

    Write-Verbose -Message "running: docker manifest create $arguments" -Verbose
    docker manifest create $arguments
    $first = $false
}

# Create the manifest

# Inspect (print) the manifest
Write-Verbose -Verbose "capturing the manifest..."
docker manifest inspect $ContainerRegistry/${Image}:$ManifestTag

# push the manifest
if (-not $SkipPush) {
    Write-Verbose -Message 'pushing manifest list...' -Verbose
    docker manifest push --purge $ContainerRegistry/${Image}:$ManifestTag
}
else {
    Write-Verbose -Message 'skipping manifest list push...' -Verbose

}
