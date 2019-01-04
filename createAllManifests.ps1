# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# script to create the Docker manifest lists
param (
    [ValidateNotNullOrEmpty()]
    [string]
    $Registry = 'microsoft',

    [ValidateSet('stable','preview','servicing')]
    [Parameter(Mandatory)]
    [string]
    $Channel='stable'
)

$createScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'createManifest.ps1'


$latestStableUbuntu   = "ubuntu-bionic"
$latestStableWsc1709  = "windowsservercore-1709"
$latestStableWscLtsc  = "windowsservercore-latest"
$latestStableWsc1803  = "windowsservercore-1803"
$latestStableWsc1809  = "windowsservercore-1809"
$latestStableNano1709 = "nanoserver-1709"
$latestStableNano1803 = "nanoserver-1803"
$latestStableNano1809 = "nanoserver-1809"

$latestPreviewUbuntu   = "preview-ubuntu-bionic"
$latestPreviewWsc1709  = "preview-windowsservercore-1709"
$latestPreviewWscLtsc  = "preview-windowsservercore-latest"
$latestPreviewWsc1803  = "preview-windowsservercore-1803"
$latestPreviewWsc1809  = "preview-windowsservercore-1809"

switch ($Channel)
{
    'preview' {
        &$createScriptPath -ContainerRegistry $Registry -taglist $latestPreviewUbuntu, $latestPreviewWsc1709, $latestPreviewWscLtsc, $latestPreviewWsc1803, $latestPreviewWsc1809  -ManifestTag 'preview'
    }

    'stable' {
        &$createScriptPath -ContainerRegistry $Registry -taglist $latestStableUbuntu, $latestStableWsc1709, $latestStableWscLtsc, $latestStableWsc1803, $latestStableWsc1809 -ManifestTag 'latest'
        &$createScriptPath -ContainerRegistry $Registry -taglist $latestStableNano1709, $latestStableNano1803, $latestStableNano1809 -ManifestTag 'nanoserver'
    }
}
