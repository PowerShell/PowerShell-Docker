# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# script to create the docker manifest lists
# Update Stable and Preview version
param (
    [ValidateNotNullOrEmpty()]
    [string]
    $Registry = 'microsoft',
    [ValidatePattern('\d+\.\d+\.\d+')]
    [string]
    $StableVersion = '6.0.2',
    [string]
    [ValidatePattern('\d+\.\d+\.\d+\-\w+\.?\d*')]
    $PreviewVersion = '6.1.0-preview.3'
)

$createScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'createManifest.ps1'


$latestStableUbuntu   = "$stableVersion-ubuntu-xenial"
$latestStableWsc1709  = "$stableVersion-windowsservercore-1709"
$latestStableWscLtsc  = "$stableVersion-windowsservercore-latest"
$latestStableWsc1803  = "$stableVersion-windowsservercore-1803"
$latestStableNano1709 = "$stableVersion-nanoserver-1709"
$latestStableNano1803 = "$stableVersion-nanoserver-1803"

$latestPreviewUbuntu    = "$previewVersion-ubuntu-xenial"
$latestPreviewWsc1709  = "$previewVersion-windowsservercore-1709"
$latestPreviewWscLtsc  = "$previewVersion-windowsservercore-latest"
$latestPreviewWsc1803  = "$previewVersion-windowsservercore-1803"
$latestPreviewNano1709 = "$previewVersion-nanoserver-1709"
$latestPreviewNano1803 = "$previewVersion-nanoserver-1803"

&$createScriptPath -ContainerRegistry $Registry -taglist $latestPreviewUbuntu, $latestPreviewWsc1709, $latestPreviewWscLtsc, $latestPreviewWsc1803  -ManifestTag 'preview'
&$createScriptPath -ContainerRegistry $Registry -taglist $latestStableUbuntu, $latestStableWsc1709, $latestStableWscLtsc, $latestStableWsc1803  -ManifestTag 'latest'
&$createScriptPath -ContainerRegistry $Registry -taglist $latestStableNano1709, $latestStableNano1803  -ManifestTag 'nanoserver'
&$createScriptPath -ContainerRegistry $Registry -taglist $latestStableNano1709, $latestStableNano1803  -ManifestTag "$stableVersion-nanoserver"

<# 
NanoServer is broken in preview.3
https://github.com/PowerShell/PowerShell/issues/6750

&$createScriptPath -ContainerRegistry $Registry -taglist $latestPreviewNano1709, $latestPreviewNano1803  -ManifestTag 'nanoserver'
&$createScriptPath -ContainerRegistry $Registry -taglist $latestPreviewNano1709, $latestPreviewNano1803  -ManifestTag "$stableVersion-nanoserver"
#> 
