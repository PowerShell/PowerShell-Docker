# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

$script:forcePull = $true
# Get docker Engine OS
function Get-DockerEngineOs
{
    docker info --format '{{ .OperatingSystem }}'
}

# Call Docker with appropriate result checksfunction Invoke-Docker
function Invoke-Docker
{
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $Command,
        [ValidateSet("error","warning",'ignore')]
        $FailureAction = 'error',

        [Parameter(Mandatory=$true)]
        [string[]]
        $Params,

        [switch]
        $PassThru,
        [switch]
        $SuppressHostOutput
    )

    $ErrorActionPreference = 'Continue'

    # Log how we are running docker for troubleshooting issues
    Write-Verbose "Running docker $command $params" -Verbose
    if($SuppressHostOutput.IsPresent)
    {
        $result = docker $command $params 2>&1
    }
    else
    {
        &'docker' $command $params 2>&1 | Tee-Object -Variable result -ErrorAction SilentlyContinue | Out-String -Stream -ErrorAction SilentlyContinue | Write-Host -ErrorAction SilentlyContinue
    }

    $dockerExitCode = $LASTEXITCODE
    if($PassThru.IsPresent)
    {
        Write-Verbose "passing through docker result$($result.length)..." -Verbose
        return $result
    }
    elseif($dockerExitCode -ne 0 -and $FailureAction -eq 'error')
    {
        Write-Error "docker $command failed with: $result" -ErrorAction Stop
        return $false
    }
    elseif($dockerExitCode -ne 0 -and $FailureAction -eq 'warning')
    {
        Write-Warning "docker $command failed with: $result"
        return $false
    }
    elseif($dockerExitCode -ne 0)
    {
        return $false
    }

    return $true
}

# Return a list of Linux Container Test Cases
function Get-LinuxContainer
{
    $testArgPath = Join-Path -Path $PSScriptRoot -ChildPath 'testArgs.json'
    $testArgsList = Get-Content $testArgPath | ConvertFrom-Json

    foreach($testArgs in $testArgsList)
    {
        if($testArgs.os -eq 'linux')
        {
            Write-Output @{
                Name = $testArgs.Tag
                Path = $testArgs.ContextPath
                BuildArgs = $testArgs.BuildArgs
                ExpectedVersion = $testArgs.ExpectedVersion
            }
        }
    }
}

# Return a list of Windows Container Test Cases
function Get-WindowsContainer
{
    $testArgPath = Join-Path -Path $PSScriptRoot -ChildPath 'testArgs.json'
    $testArgsList = Get-Content $testArgPath | ConvertFrom-Json

    foreach($testArgs in $testArgsList)
    {
        if($testArgs.os -eq 'windows')
        {
            Write-Output @{
                Name = $testArgs.Tag
                Path = $testArgs.ContextPath
                BuildArgs = $testArgs.BuildArgs
                ExpectedVersion = $testArgs.ExpectedVersion
            }
        }
    }
}

function Test-SkipWindows
{
    [bool] $canRunWindows = (Get-DockerEngineOs) -like 'Windows*'
    return ($IsLinux -or $IsMacOS -or !$canRunWindows)
}

function Test-SkipLinux
{
    $os = Get-DockerEngineOs

    switch -wildcard ($os)
    {
        '*Linux*' {
            return $false
        }
        '*Mac' {
            return $false
        }
        # Docker for Windows means we are running the linux kernel
        'Docker for Windows' {
            return $false
        }
        'Windows*' {
            return $true
        }
        default {
            throw "Unknow docker os '$os'"
        }
    }
}

function Get-TestContext
{
    param(
        [ValidateSet('Linux','Windows','macOS')]
        [string]$Type
    )

    $resultFileName = 'results.xml'
    $logFileName = 'results.log'
    $containerTestDrive = '/test'

    # Return a windows context if the Context in Windows *AND*
    # the current system is windows, otherwise Join-path will fail.
    if($Type -eq 'Windows' -and $IsWindows)
    {
        $ContainerTestDrive = 'C:\test'
    }
    $resolvedTestDrive = (Resolve-Path "Testdrive:\").providerPath

    return @{
        ResolvedTestDrive = $resolvedTestDrive
        ResolvedXmlPath = Join-Path $resolvedTestDrive -ChildPath $resultFileName
        ResolvedLogPath = Join-Path $resolvedTestDrive -ChildPath $logFileName
        ContainerTestDrive = $ContainerTestDrive
        ContainerXmlPath = Join-Path $containerTestDrive -ChildPath $resultFileName
        ContainerLogPath = Join-Path $containerTestDrive -ChildPath $logFileName
        Type = $Type
        ForcePull = $script:forcePull
    }
}

function Get-ContainerPowerShellVersion
{
    param(
        [HashTable] $TestContext,
        [string] $Name
    )

    $imageTag = ${Name}

    if($TestContext.ForcePull)
    {
        $null=Invoke-Docker -Command 'image', 'pull' -Params $imageTag -SuppressHostOutput
    }

    $runParams = @()
    $localVolumeName = $testContext.resolvedTestDrive
    $runParams += '--rm'
    if($TestContext.Type -ne 'Windows' -and $isWindows)
    {
        # use a container volume on windows because host volumes are not automatic
        $volumeName = "test-volume-" + (Get-Random -Minimum 100 -Maximum 999)

        # using alpine because it's tiny
        $null=Invoke-Docker -Command create -Params '-v', '/test', '--name', $volumeName, 'alpine' -SuppressHostOutput
        $runParams += '--volumes-from'
        $runParams += $volumeName
    }
    else {
        $runParams += '-v'
        $runParams += "${localVolumeName}:$($testContext.containerTestDrive)"
    }

    $runParams += $imageTag
    $runParams += 'pwsh'
    $runParams += '-c'
    $runParams += ('$PSVersionTable.PSVersion.ToString() | out-string | out-file -encoding ascii -FilePath '+$testContext.containerLogPath)

    $null = Invoke-Docker -Command run -Params $runParams -SuppressHostOutput
    if($TestContext.Type -ne 'Windows' -and $isWindows)
    {
        $null = Invoke-Docker -Command cp -Params "${volumeName}:$($testContext.containerLogPath)", $TestContext.ResolvedLogPath
        $null = Invoke-Docker -Command container, rm -Params $volumeName, '--force' -SuppressHostOutput
    }
    return (Get-Content -Encoding Ascii $testContext.resolvedLogPath)[0]
}
