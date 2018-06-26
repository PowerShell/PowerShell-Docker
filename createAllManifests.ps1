# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# script to create the docker manifest lists
param (
    [ValidateNotNullOrEmpty()]
    [string]
    $Registry = 'microsoft'
)

$createScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'createManifest.ps1'


$latestStableUbuntu   = "ubuntu-xenial"
$latestStableWsc1709  = "windowsservercore-1709"
$latestStableWscLtsc  = "windowsservercore-latest"
$latestStableWsc1803  = "windowsservercore-1803"
$latestStableNano1709 = "nanoserver-1709"
$latestStableNano1803 = "nanoserver-1803"

$latestPreviewUbuntu   = "preview-ubuntu-xenial"
$latestPreviewWsc1709  = "preview-windowsservercore-1709"
$latestPreviewWscLtsc  = "preview-windowsservercore-latest"
$latestPreviewWsc1803  = "preview-windowsservercore-1803"
$latestPreviewNano1709 = "preview-nanoserver-1709"
$latestPreviewNano1803 = "preview-nanoserver-1803"

&$createScriptPath -ContainerRegistry $Registry -taglist $latestPreviewUbuntu, $latestPreviewWsc1709, $latestPreviewWscLtsc, $latestPreviewWsc1803  -ManifestTag 'preview'
&$createScriptPath -ContainerRegistry $Registry -taglist $latestStableUbuntu, $latestStableWsc1709, $latestStableWscLtsc, $latestStableWsc1803  -ManifestTag 'latest'
&$createScriptPath -ContainerRegistry $Registry -taglist $latestStableNano1709, $latestStableNano1803  -ManifestTag 'nanoserver'
&$createScriptPath -ContainerRegistry $Registry -taglist $latestStableNano1709, $latestStableNano1803  -ManifestTag "nanoserver"

<# 
NanoServer is broken in preview.3
https://github.com/PowerShell/PowerShell/issues/6750

&$createScriptPath -ContainerRegistry $Registry -taglist $latestPreviewNano1709, $latestPreviewNano1803  -ManifestTag 'nanoserver'
&$createScriptPath -ContainerRegistry $Registry -taglist $latestPreviewNano1709, $latestPreviewNano1803  -ManifestTag "nanoserver"
#> 
