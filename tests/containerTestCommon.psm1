# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Get Docker Engine OS
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
        $UseAcr,

        [switch]
        $SuppressHostOutput
    )

    $ErrorActionPreference = 'Continue'

    $cliCommand = @()
    if($UseAcr)
    {
        $cli = @('az')
        $cliCommand += 'acr'
    }
    else {
        $cli = @('docker')
    }

    # Log how we are running Docker for troubleshooting issues
    Write-Verbose "Running $cli $cliCommand $command $params" -Verbose

    if($SuppressHostOutput.IsPresent)
    {
        $result = &$cli $cliCommand $command $params 2>&1
    }
    else
    {
        &$cli $cliCommand $command $params 2>&1 | Tee-Object -Variable result -ErrorAction SilentlyContinue | Out-String -Stream -ErrorAction SilentlyContinue | Write-Host -ErrorAction SilentlyContinue
    }

    $dockerExitCode = $LASTEXITCODE
    if($PassThru.IsPresent)
    {
        Write-Verbose "passing through docker results of length: $($result.length)..." -Verbose
        return $result
    }
    elseif($dockerExitCode -ne 0 -and $FailureAction -eq 'error')
    {
        $resultString = $result | out-string -Width 9999
        if($result.length -gt 80)
        {
            $filename = [System.io.path]::GetTempFileName() + ".txt"
            $resultString | Out-File -FilePath $filename
            if($env:TF_BUILD)
            {
                Write-Host "##vso[artifact.upload containerfolder=errorLogs;artifactname=errorLogs]$filename"
            }

            Write-Error "docker $command failed, see $filename ($($result.length))" -ErrorAction Stop
        }
        else
        {
            Write-Error "docker $command failed with: $resultString  ($($result.length))" -ErrorAction Stop
        }

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
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Verification','Build','All')]
        [String]
        $Purpose
    )

    $testArgPath = Join-Path -Path $PSScriptRoot -ChildPath 'testArgs.json'
    $testArgsList = Get-Content $testArgPath | ConvertFrom-Json

    foreach($testArgs in $testArgsList)
    {
        # Only return results where:
        # OS eq linux
        # not (purpose eq verification -and SkipVerification)
        if($testArgs.os -eq 'linux' -and !($Purpose -eq 'Verification' -and $testArgs.SkipVerification))
        {
            Write-Output @{
                Name = $testArgs.Tags[0]
                Tags = $testArgs.Tags
                Path = $testArgs.ContextPath
                BuildArgs = $testArgs.BuildArgs
                ExpectedVersion = $testArgs.ExpectedVersion
                SkipWebCmdletTests = $testArgs.SkipWebCmdletTests
                ImageName = $testArgs.BuildArgs.IMAGE_NAME
            }
        }
    }
}

# Return a list of Windows Container Test Cases
function Get-WindowsContainer
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Verification','Build','All')]
        [String]
        $Purpose
    )

    $testArgPath = Join-Path -Path $PSScriptRoot -ChildPath 'testArgs.json'
    $testArgsList = Get-Content $testArgPath | ConvertFrom-Json

    foreach($testArgs in $testArgsList)
    {
        if($testArgs.os -eq 'windows' -and !($Purpose -eq 'Verification' -and $testArgs.SkipVerification))
        {
            Write-Output @{
                Name = $testArgs.Tags[0]
                Tags = $testArgs.Tags
                Path = $testArgs.ContextPath
                BuildArgs = $testArgs.BuildArgs
                ExpectedVersion = $testArgs.ExpectedVersion
                SkipWebCmdletTests = $testArgs.SkipWebCmdletTests
                ImageName = $testArgs.BuildArgs.IMAGE_NAME
            }
        }
    }
}

function Test-SkipWindows
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Verification','Build','All')]
        [String]
        $Purpose
    )

    [bool] $canRunWindows = (Get-DockerEngineOs) -like 'Windows*'
    return ($IsLinux -or $IsMacOS -or !$canRunWindows)
}

function Test-SkipLinux
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Verification','Build','All')]
        [String]
        $Purpose
    )

    $os = Get-DockerEngineOs

    switch -wildcard ($os)
    {
        '*Linux*' {
            return $false
        }
        '*Mac' {
            return $false
        }
        'Ubuntu*' {
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
    }
}

function Get-ContainerPowerShellVersion
{
    param(
        [HashTable] $TestContext,
        [string] $Name
    )

    $imageTag = ${Name}

    $runParams = @()
    $runParams += '--rm'

    $runParams += $imageTag
    $runParams += 'pwsh'
    $runParams += '-nologo'
    $runParams += '-noprofile'
    $runParams += '-c'
    $runParams += '$PSVersionTable.PSVersion.ToString()'

    $version = Invoke-Docker -Command run -Params $runParams -SuppressHostOutput -PassThru
    return $version
}

function Get-MetadataUsingContainer
{
    param(
        [string] $Name,
        [ValidateSet('StableReleaseTag','PreviewReleaseTag','ServicingReleaseTag')]
        [string] $Property = "StableReleaseTag"
    )

    $imageTag = ${Name}

    $runParams = @()
    $runParams += '--rm'

    $runParams += $imageTag
    $runParams += 'pwsh'
    $runParams += '-nologo'
    $runParams += '-noprofile'
    $runParams += '-c'
    $runParams += '(Invoke-WebRequest -Uri "https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json").Content'

    return Invoke-Docker -Command run -Params $runParams -SuppressHostOutput -PassThru
}

function Get-UICultureUsingContainer
{
    param(
        [string] $Name
    )

    $imageTag = ${Name}

    $runParams = @()
    $runParams += '--rm'

    $runParams += $imageTag
    $runParams += 'pwsh'
    $runParams += '-nologo'
    $runParams += '-noprofile'
    $runParams += '-c'
    $runParams += '(Get-UICulture).Name'

    return Invoke-Docker -Command run -Params $runParams -SuppressHostOutput -PassThru
}

function Get-DockerImageLabel
{
    param(
        [string] $Name,
        [String] $Label
    )

    $imageTag = ${Name}

    $runParams = @()
    $runParams += '--format'

    $runParams += "'{{ index .Config.Labels \`"$Label\`"}}'"
    $runParams += $imageTag

    return Invoke-Docker -Command inspect -Params $runParams -SuppressHostOutput -PassThru
}

# Builds a docker image
function Invoke-DockerBuild
{
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $Tags,

        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter(Mandatory=$true)]
        [object]
        $BuildArgs,

        [Parameter(Mandatory=$true)]
        [ValidateSet('windows','linux')]
        [string]
        $OSType
    )


    $buildArgNames = $BuildArgs | Get-Member -Type NoteProperty | Select-Object -ExpandProperty Name

    $buildArgList = @()

    $extraParams = @{}
    if($env:ACR_NAME)
    {
        $extraParams.Add('UseAcr',$true)
        $buildArgList += @(
            '-r'
            $env:ACR_NAME
            '--os'
            $OSType
        )
    }
    else {
        $buildArgList += '--pull'
        $buildArgList += '--quiet'
    }

    foreach($argName in $buildArgNames)
    {
        $value = $BuildArgs.$argName
        if($env:ACR_NAME)
        {
            # & must be escaped in ACR
            $value = $value -replace '&', '%26'
        }

        $buildArgList += @(
            "--build-arg"
            "$argName=$value"
        )
    }

    foreach($tag in $Tags)
    {
        $buildArgList += @(
            "-t"
            $tag
        )
    }

    Invoke-Docker -Command build -Params @(
            $buildArgList
            $path
        ) -SuppressHostOutput @extraParams
}
