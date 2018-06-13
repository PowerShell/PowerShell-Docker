# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Import-module -Name "$PSScriptRoot\containerTestCommon.psm1" -Force
$script:linuxContainerTests = Get-LinuxContainer
$script:windowsContainerTests = Get-WindowsContainer
$script:skipLinux = (Test-SkipLinux) -or !$script:linuxContainerTests
$script:skipWindows = (Test-SkipWindows) -or !$script:windowsContainerTests

Describe "Build Linux Containers" -Tags 'Build', 'Linux' {
    BeforeAll {
    }

    it "<Name> builds from '<path>'" -TestCases $script:linuxContainerTests -Skip:$script:skipLinux {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [Parameter(Mandatory=$true)]
            [string]
            $path,

            [Parameter(Mandatory=$true)]
            [object]
            $BuildArgs,

            [Parameter(Mandatory=$true)]
            [string]
            $ExpectedVersion
        )

        $buildArgNames = $BuildArgs | get-member -Type NoteProperty | Select-Object -ExpandProperty Name

        $buildArgList = @()
        foreach($argName in $buildArgNames)
        {
            $value = $BuildArgs.$argName
            $buildArgList += @(
                "--build-arg"
                "$argName=$value"
            )
        }

        { Invoke-Docker -Command build -Params @(
                '--pull'
                '--quiet'
                '-t'
                ${Name}
                $buildArgList
                $path 
            ) -SuppressHostOutput} | should -not -throw
    }
}

Describe "Build Windows Containers" -Tags 'Build', 'Windows' {
    it "<Name> builds from '<path>'" -TestCases $script:windowsContainerTests  -skip:$script:skipWindows {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [Parameter(Mandatory=$true)]
            [string]
            $path,

            [Parameter(Mandatory=$true)]
            [object]
            $BuildArgs,

            [Parameter(Mandatory=$true)]
            [string]
            $ExpectedVersion
        )

        $buildArgNames = $BuildArgs | get-member -Type NoteProperty | Select-Object -ExpandProperty Name

        $buildArgList = @()
        foreach($argName in $buildArgNames)
        {
            $value = $BuildArgs.$argName
            $buildArgList += @(
                "--build-arg"
                "$argName=$value"
            )
        }

        { Invoke-Docker -Command build -Params @(
                '--pull'
                '--quiet'
                '-t'
                ${Name}
                $buildArgList
                $path 
            ) -SuppressHostOutput} | should -not -throw
    }
}

Describe "Linux Containers run PowerShell" -Tags 'Behavior', 'Linux' {
    BeforeAll{
        $testContext = Get-TestContext -type Linux
    }
    AfterAll{
        # prune unused volumes
        $null=Invoke-Docker -Command 'volume', 'prune' -Params '--force' -SuppressHostOutput
    }
    BeforeEach {
        Remove-Item $testContext.resolvedXmlPath -ErrorAction SilentlyContinue
        Remove-Item $testContext.resolvedLogPath -ErrorAction SilentlyContinue
    }

    it "Get PSVersion table from <Name> should be <ExpectedVersion>" -TestCases $script:linuxContainerTests -Skip:$script:skipLinux {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [Parameter(Mandatory=$true)]
            [string]
            $path,

            [Parameter(Mandatory=$true)]
            [object]
            $BuildArgs,

            [Parameter(Mandatory=$true)]
            [string]
            $ExpectedVersion
        )

        Get-ContainerPowerShellVersion -TestContext $testContext -Name $Name | should -be $ExpectedVersion
    }
}

Describe "Windows Containers run PowerShell" -Tags 'Behavior', 'Windows' {
    BeforeAll{
        $testContext = Get-TestContext -type Windows
    }
    BeforeEach {
        Remove-Item $testContext.resolvedXmlPath -ErrorAction SilentlyContinue
        Remove-Item $testContext.resolvedLogPath -ErrorAction SilentlyContinue
    }

    it "Get PSVersion table from <Name> should be <ExpectedVersion>" -TestCases $script:windowsContainerTests -skip:$script:skipWindows {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [Parameter(Mandatory=$true)]
            [string]
            $path,

            [Parameter(Mandatory=$true)]
            [object]
            $BuildArgs,

            [Parameter(Mandatory=$true)]
            [string]
            $ExpectedVersion
        )

        Get-ContainerPowerShellVersion -TestContext $testContext -Name $Name | should -be $ExpectedVersion
    }
}
