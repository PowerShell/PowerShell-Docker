# Copyright (c) Microsoft Corporation. 
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
$latestStableWsc1809  = "windowsservercore-1809"
$latestStableWsc1903  = "windowsservercore-1903"
$latestStableNano1809 = "nanoserver-1809"
$latestStableNano1903 = "nanoserver-1903"

$latestPreviewUbuntu  = "preview-ubuntu-bionic"
$latestPreviewWsc1809 = "preview-windowsservercore-1809"
$latestPreviewWsc1903 = "preview-windowsservercore-1809"

switch ($Channel)
{
    'preview' {
        &$createScriptPath -ContainerRegistry $Registry -taglist $latestPreviewUbuntu, $latestPreviewWsc1903, $latestPreviewWsc1809 -ManifestTag 'preview'
    }

    'stable' {
        &$createScriptPath -ContainerRegistry $Registry -taglist $latestStableUbuntu, $latestStableWsc1903, $latestStableWsc1809 -ManifestTag 'latest'
        &$createScriptPath -ContainerRegistry $Registry -taglist $latestStableNano1903, $latestStableNano1809 -ManifestTag 'nanoserver'
    }
}
