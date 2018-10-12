# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Import-module -Name "$PSScriptRoot\containerTestCommon.psm1" -Force
$script:linuxContainerBuildTests = Get-LinuxContainer -Purpose 'Build'
$script:windowsContainerBuildTests = Get-WindowsContainer -Purpose 'Build'
$script:linuxContainerRunTests = Get-LinuxContainer -Purpose 'Verification'
$script:windowsContainerRunTests = Get-WindowsContainer -Purpose 'Verification'
$script:skipLinux = (Test-SkipLinux -Purpose 'Build') -or !$script:linuxContainerBuildTests
$script:skipWindows = (Test-SkipWindows -Purpose 'Build') -or !$script:windowsContainerBuildTests
$script:skipLinuxRun = (Test-SkipLinux -Purpose 'Verification') -or !$script:linuxContainerRunTests
$script:skipWindowsRun = (Test-SkipWindows -Purpose 'Verification') -or !$script:windowsContainerRunTests

Describe "Build Linux Containers" -Tags 'Build', 'Linux' {
    BeforeAll {
    }

    it "<Name> builds from '<path>'" -TestCases $script:linuxContainerBuildTests -Skip:$script:skipLinux {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $name,

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
            [string]
            $ExpectedVersion
        )

        Invoke-DockerBuild -Tags $Tags -Path $Path -BuildArgs $BuildArgs -OSType linux
    }
}

Describe "Build Windows Containers" -Tags 'Build', 'Windows' {
    it "<Name> builds from '<path>'" -TestCases $script:windowsContainerBuildTests  -skip:$script:skipWindows {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $name,

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
            [string]
            $ExpectedVersion
        )

        Invoke-DockerBuild -Tags $Tags -Path $Path -BuildArgs $BuildArgs -OSType windows
    }
}

Describe "Pull Linux Containers" -Tags 'Linux', 'Pull' {
    It "<Name> pulls without error" -TestCases $script:linuxContainerRunTests -Skip:$script:skipLinuxRun {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [Parameter(Mandatory=$true)]
            [string[]]
            $Tags,

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

        foreach($tag in $tags) {
            Invoke-Docker -Command pull -Params @(
                    ${tag}
                ) -SuppressHostOutput
        }
    }
}

Describe "Pull Windows Containers" -Tags 'Windows', 'Pull' {
    it "<Name> pulls without error" -TestCases $script:windowsContainerRunTests  -skip:$script:skipWindowsRun {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [Parameter(Mandatory=$true)]
            [string[]]
            $Tags,

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

        foreach($tag in $tags) {
            Invoke-Docker -Command pull -Params @(
                    ${tag}
                ) -SuppressHostOutput
        }
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

    Context "Run Powershell" {
        it "Get PSVersion table from <Name> should be <ExpectedVersion>" -TestCases $script:linuxContainerRunTests -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,

                [Parameter(Mandatory=$true)]
                [string[]]
                $Tags,

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

            if($Name -match '6\.1\.0\-rc\.1\-alpine')
            {
                # 6.1.0-rc.1-apline was published with 6.1.0-fixalpine as the version
                $ExpectedVersion = '6.1.0-fixalpine'
            }

            Get-ContainerPowerShellVersion -TestContext $testContext -Name $Name | should -be $ExpectedVersion
        }

        it "Invoke-WebRequest from <Name> should not fail" -TestCases $script:linuxContainerRunTests -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,

                [Parameter(Mandatory=$true)]
                [string[]]
                $Tags,

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

            $metadataString = Get-MetadataUsingContainer -Name $Name
            $metadataString | Should -Not -BeNullOrEmpty
            $metadataJson = $metadataString | ConvertFrom-Json -ErrorAction Stop
            $metadataJson | Select-Object -ExpandProperty StableReleaseTag | Should -Match '^v\d+\.\d+\.\d+.*$'
        }

        it "Get-UICulture from <Name> should return en-US" -TestCases $script:linuxContainerRunTests -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,

                [Parameter(Mandatory=$true)]
                [string[]]
                $Tags,

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

            $culture = Get-UICultureUsingContainer -Name $Name
            $culture | Should -Not -BeNullOrEmpty
            $culture | Should -BeExactly 'en-US'
        }
    }

    Context "Labels" {
        $labelTestCases = @()
        $script:linuxContainerRunTests | ForEach-Object {
            $labelTestCases += @{
                Name = $_.Name
                Label = 'org.label-schema.version'
                # The expected value is the version, but replace - or ~ with the regex for - or ~
                ExpectedValue = $_.ExpectedVersion  -replace '[\-~]', '[\-~]'
                Expectation = 'Match'
            }
            $labelTestCases += @{
                Name = $_.Name
                Label = 'org.label-schema.vcs-ref'
                ExpectedValue = '[0-9a-f]{7}'
                Expectation = 'match'
            }
            $labelTestCases += @{
                Name = $_.Name
                Label = 'org.label-schema.docker.cmd.devel'
                ExpectedValue = "docker run $('mcr.microsoft.com/powershell:' + ($_.Name -split ':')[1])"
                Expectation = 'BeExactly'
            }
        }

        it "Image <Name> should have label: <Label>, with value: <ExpectedValue>" -TestCases $labelTestCases -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,

                [Parameter(Mandatory=$true)]
                [string[]]
                $Label,

                [Parameter(Mandatory=$true)]
                [string]
                $ExpectedValue,

                [Parameter(Mandatory=$true)]
                [ValidateSet('Match','BeExactly')]
                [string]
                $Expectation
            )

            $labelValue = Get-DockerImageLabel -Name $Name -Label $Label
            $labelValue | Should -Not -BeNullOrEmpty

            switch($Expectation)
            {
                'Match' {
                    $labelValue | Should -Match "'$ExpectedValue'"
                }
                'BeExactly' {
                    $labelValue | Should -BeExactly "'$ExpectedValue'"
                }
                default {
                    throw "Unexpected expactation '$Expectation'"
                }
            }
        }
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

    it "Get PSVersion table from <Name> should be <ExpectedVersion>" -TestCases $script:windowsContainerRunTests -skip:$script:skipWindowsRun {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [Parameter(Mandatory=$true)]
            [string[]]
            $Tags,

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

    it "Invoke-WebRequest from <Name> should not fail" -TestCases $script:windowsContainerRunTests -skip:$script:skipWindowsRun {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [Parameter(Mandatory=$true)]
            [string[]]
            $Tags,

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

        $metadataString = Get-MetadataUsingContainer -Name $Name
        $metadataString | Should -Not -BeNullOrEmpty
        $metadataJson = $metadataString | ConvertFrom-Json -ErrorAction Stop
        $metadataJson | Select-Object -ExpandProperty StableReleaseTag | Should -Match '^v\d+\.\d+\.\d+.*$'
    }
}

Describe "Push Linux Containers" -Tags 'Linux', 'Push' {
    BeforeAll{
        $pushTestCases = @()
        $script:linuxContainerRunTests | ForEach-Object {
            $pushTestCases += @{
                Tags = $_.Tags
                Name = $_.Name
            }
        }
    }

    It "<Name> pushes without error" -TestCases $pushTestCases -Skip:$script:skipLinuxRun {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $Name,

            [Parameter(Mandatory=$true)]
            [string[]]
            $Tags
        )

        foreach($tag in $tags) {
            Invoke-Docker -Command push -Params @(
                    ${tag}
                ) -SuppressHostOutput
        }
    }
}

Describe "Push Windows Containers" -Tags 'Windows', 'Push' {
    BeforeAll{
        $pushTestCases = @()
        $script:windowsContainerRunTests | ForEach-Object {
            $pushTestCases += @{
                Tags = $_.Tags
                Name = $_.Name
            }
        }
    }

    it "<Name> Pushes without error" -TestCases $pushTestCases  -skip:$script:skipWindowsRun {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $Name,

            [Parameter(Mandatory=$true)]
            [string[]]
            $Tags
        )

        foreach($tag in $tags) {
            Invoke-Docker -Command push -Params @(
                    ${tag}
                ) -SuppressHostOutput
        }
    }
}
