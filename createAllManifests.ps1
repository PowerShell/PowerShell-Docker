# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# script to create the Docker manifest lists
param (
    [ValidateNotNullOrEmpty()]
    [string]
    $Registry = 'microsoft',

    [ValidateSet('stable','preview','servicing', 'lts')]
    [Parameter(Mandatory)]
    [string]
    $Channel='stable',

    [switch]
    $SkipPush
)

# this function wraps native command Execution
# for more information, read https://mnaoumov.wordpress.com/2015/01/11/execution-of-external-commands-in-powershell-done-right/
function script:Start-NativeExecution
{
    param(
        [scriptblock]$sb,
        [switch]$IgnoreExitcode,
        [switch]$VerboseOutputOnError
    )

    Write-Verbose -Message "Running '$($sb.ToString())'" -Verbose
    $backupEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        if($VerboseOutputOnError.IsPresent)
        {
            $output = & $sb 2>&1
        }
        else
        {
            & $sb
        }

        # note, if $sb doesn't have a native invocation, $LASTEXITCODE will
        # point to the obsolete value
        if ($LASTEXITCODE -ne 0 -and -not $IgnoreExitcode) {
            if($VerboseOutputOnError.IsPresent -and $output)
            {
                $output | Out-String | Write-Verbose -Verbose
            }

            # Get caller location for easier debugging
            $caller = Get-PSCallStack -ErrorAction SilentlyContinue
            if($caller)
            {
                $callerLocationParts = $caller[1].Location -split ":\s*line\s*"
                $callerFile = $callerLocationParts[0]
                $callerLine = $callerLocationParts[1]

                $errorMessage = "Execution of {$sb} by ${callerFile}: line $callerLine failed with exit code $LASTEXITCODE"
                throw $errorMessage
            }
            throw "Execution of {$sb} failed with exit code $LASTEXITCODE"
        }
    } finally {
        $ErrorActionPreference = $backupEAP
    }
}

$buildScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'build.ps1'

$createScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'createManifest.ps1'

$extraParams = ''

if ($env:STABLERELEASETAG) {
    $extraParams += " -StableVersion $($env:STABLERELEASETAG -replace '^v')"
}

if ($env:PREVIEWRELEASETAG) {
    $extraParams += " -PreviewVersion $($env:PREVIEWRELEASETAG -replace '^v')"
}

if ($env:LTSRELEASETAG) {
    $extraParams += " -LtsVersion $($env:LTSRELEASETAG -replace '^v')"
}

$json = Start-NativeExecution -sb ([scriptblock]::Create("$buildScriptPath -GenerateManifestLists -Channel $Channel -OsFilter All $extraParams"))

$manifestLists = $json | ConvertFrom-Json

$manifestLists.ManifestList | ForEach-Object {
    $tag = $_
    $manifestList = $manifestLists | Where-Object {$_.ManifestList -eq $tag}
    Start-NativeExecution -sb ([scriptblock]::Create("$createScriptPath -ContainerRegistry $Registry -taglist $($manifestList.Tags -join ', ') -ManifestTag $tag -SkipPush:`$$($SkipPush.IsPresent)"))
}
