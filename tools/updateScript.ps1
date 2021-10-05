# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

$yamlPath = "$psscriptroot\..\.vsts-ci/releasebuild.yml"
$yaml = Get-Content -Path $yamlPath
$defaults = $yaml | Select-String -Pattern '^\s* default:\s(v\d*\.\d*\.\d*(-\w*\.\d*)?)$'

$retryCount = 3
$retryIntervalSec = 15
function Get-ChannelMeta {
    param(
        [ValidateSet('Stable', 'Preview', 'Lts', 'Daily')]
        [string]
        $Channel = 'Stable'
    )

    $urlTemplate = 'https://github.com/PowerShell/PowerShell/releases/download/v{0}/powershell-{0}-osx-x64.tar.gz'

    switch ($Channel) {
        'Stable' {
            $metadata = Invoke-RestMethod 'https://aka.ms/pwsh-buildinfo-stable' -MaximumRetryCount $retryCount -RetryIntervalSec $retryIntervalSec
        }
        'Lts' {
            $metadata = Invoke-RestMethod 'https://aka.ms/pwsh-buildinfo-lts' -MaximumRetryCount $retryCount -RetryIntervalSec $retryIntervalSec
        }
        'Preview' {
            $metadata = Invoke-RestMethod 'https://aka.ms/pwsh-buildinfo-preview' -MaximumRetryCount $retryCount -RetryIntervalSec $retryIntervalSec
        }
        'Daily' {
            $metadata = Invoke-RestMethod 'https://aka.ms/pwsh-buildinfo-Daily' -MaximumRetryCount $retryCount -RetryIntervalSec $retryIntervalSec
            $urlTemplate = "https://pscoretestdata.blob.core.windows.net/$($metadata.blobname)/powershell-{0}-osx-x64.tar.gz"
        }
        default {
            throw "Invalid channel: $Channel"
        }
    }

    return [PSCustomObject]@{
        MetaData    = $metadata
        UrlTemplate = $urlTemplate
    }
}

$updated = $false
foreach ($default in $defaults) {
    $existingReleaseTag = $default.Matches.groups[1]
    $channel = switch -Regex ($existingReleaseTag) {
        ('^v7\.0') {
            "LTS"
        }
        ('^v7\.1') {
            "Stable"
        }
        ('^v.*-preview\.\d*') {
            "Preview"
        }
        default {
            throw "Don't know the channel for $existingReleaseTag"
        }
    }
    $meta = Get-ChannelMeta -Channel $channel
    $newReleaseTag = $meta.metadata.ReleaseTag
    $existingReleaseTagRegEx = [regex]::Escape($existingReleaseTag)
    if ($existingReleaseTag.ToString() -ne $newReleaseTag.ToString()) {
        Write-Verbose -Message "replacing '$existingReleaseTag' with '$newReleaseTag' - $($existingReleaseTag -ne $newReleaseTag)" -Verbose
        $yaml = $yaml -replace $existingReleaseTag, $newReleaseTag
        $updated = $true
    }
    # @{
    #     ExistingReleaseTag = $existingReleaseTag
    #     ExpectedReleaseTag = $newReleaseTag
    #     Channel = $channel
    #     Line = $default.Line
    #     LineNumber = $default.LineNumber
    # }
}
if ($updated) {
    Write-Verbose "New Yaml (first 15 lines):" -Verbose
    $yaml | Select-Object -First 15 | Write-Verbose -Verbose
    Write-Verbose "Saving new yaml..." -Verbose
    $yaml | Out-File -FilePath $yamlPath
}
