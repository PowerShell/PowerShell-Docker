# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

param(
    [string]
    $StableVersion,

    [string]
    $PreviewVersion,

    [string]
    $LtsVersion
)

if (!($stableVersion -eq ""))
{
  if ($stableVersion -notmatch '\d+\.\d+\.\d+$') {
    throw "stable release tag is not for a stable build: '$stableVersion'"
  }
}

if (!($previewVersion -eq ""))
{
  if ($previewVersion -notmatch '\d+\.\d+\.\d+-(preview|rc)\.\d+$') {
    throw "preview release tag is not for a preview build: '$previewVersion'"
  }
}

if (!($ltsVersion -eq ""))
{
  if ($ltsVersion -notmatch '\d+\.\d+\.\d+$') {
    throw "lts release tag is not for a lts build: '$ltsVersion'"
  }
}

function Update-ChannelReleaseStageYaml {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('stable', 'preview', 'lts')]
        [string]
        $Channel,

        [string]
        $Version
    )

    $toolsFolderPath = Split-Path -Parent $PSScriptRoot
    $repoRoot = Split-Path -Parent $toolsFolderPath
    $buildHelperFolderPath = Join-Path -Path $toolsFolderPath -ChildPath 'buildHelper'
    $buildHelperModulePath = Join-Path -Path $buildHelperFolderPath -ChildPath 'buildHelper.psm1'
    Import-Module $buildHelperModulePath
    $buildScriptPath = Join-Path -Path $repoRoot -ChildPath "build.ps1"
    if (!($Version -eq ""))
    {
      Write-Verbose -Verbose "using $Channel version: $Version"
      if ($Channel -eq "stable")
      {
        & $buildScriptPath -UpdateBuildYaml -Channel $Channel -StableVersion $Version -Verbose -Acr All -OsFilter All
      }
      elseif ($Channel -eq "preview")
      {
        & $buildScriptPath -UpdateBuildYaml -Channel $Channel -PreviewVersion $Version -Verbose -Acr All -OsFilter All
      }
      else #Channel lts
      {
        & $buildScriptPath -UpdateBuildYaml -Channel $Channel -LtsVersion $Version -Verbose -Acr All -OsFilter All
      }
    }
    else
    {
      Write-Verbose -Verbose "using $Channel only"
      & $buildScriptPath -UpdateBuildYaml -Channel $Channel -Verbose -Acr All -OsFilter All
    }
}


# Update stableReleaseStage.yml
Update-ChannelReleaseStageYaml -Channel stable -Version $stableVersion

# Update previewReleaseStage.yml
Update-ChannelReleaseStageYaml -Channel preview -Version $previewVersion

# Update ltsReleaseStage.yml
Update-ChannelReleaseStageYaml -Channel lts -Version $ltsVersion

