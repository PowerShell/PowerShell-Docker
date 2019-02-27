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
        $buildTestCases = @()
        $script:linuxContainerBuildTests | ForEach-Object {
            $buildTestCases += @{
                Name = $_.Name
                Tags = $_.Tags
                Path = $_.Path
                BuildArgs = $_.BuildArgs
            }
        }
    }

    it "<Name> builds from '<path>'" -TestCases $buildTestCases -Skip:$script:skipLinux {
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
            $BuildArgs
        )

        Invoke-DockerBuild -Tags $Tags -Path $Path -BuildArgs $BuildArgs -OSType linux
    }
}

Describe "Build Windows Containers" -Tags 'Build', 'Windows' {
    BeforeAll {
        $buildTestCases = @()
        $script:windowsContainerBuildTests | ForEach-Object {
            $buildTestCases += @{
                Name = $_.Name
                Tags = $_.Tags
                Path = $_.Path
                BuildArgs = $_.BuildArgs
            }
        }
    }

    it "<Name> builds from '<path>'" -TestCases $buildTestCases -skip:$script:skipWindows {
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
            $BuildArgs
        )

        Invoke-DockerBuild -Tags $Tags -Path $Path -BuildArgs $BuildArgs -OSType windows
    }
}

Describe "Pull Linux Containers" -Tags 'Linux', 'Pull' {
    BeforeAll {
        $pullTestCases = @()
        $script:linuxContainerRunTests | ForEach-Object {
            $pullTestCases += @{
                Name = $_.Name
                Tags = $_.Tags
            }
        }
    }

    It "<Name> pulls without error" -TestCases $pullTestCases -Skip:$script:skipLinuxRun {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [Parameter(Mandatory=$true)]
            [string[]]
            $Tags
        )

        foreach($tag in $tags) {
            Invoke-Docker -Command pull -Params @(
                    ${tag}
                ) -SuppressHostOutput
        }
    }
}

Describe "Pull Windows Containers" -Tags 'Windows', 'Pull' {
    BeforeAll {
        $pullTestCases = @()
        $script:windowsContainerRunTests | ForEach-Object {
            $pullTestCases += @{
                Name = $_.Name
                Tags = $_.Tags
            }
        }
    }
    it "<Name> pulls without error" -TestCases $pullTestCases  -skip:$script:skipWindowsRun {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [Parameter(Mandatory=$true)]
            [string[]]
            $Tags
        )

        foreach($tag in $tags) {
            Invoke-Docker -Command pull -Params @(
                    ${tag}
                ) -SuppressHostOutput
        }
    }
}

Describe "Linux Containers" -Tags 'Behavior', 'Linux' {
    BeforeAll{
        $testContext = Get-TestContext -type Linux
        $runTestCases = @()
        $script:linuxContainerRunTests | ForEach-Object {
            $runTestCases += @{
                Name = $_.Name
                ExpectedVersion = $_.ExpectedVersion
            }
        }

        $webTestCases = @()
        $script:linuxContainerRunTests | Where-Object {$_.SkipWebCmdletTests -ne $true} | ForEach-Object {
            $webTestCases += @{
                Name = $_.Name
            }
        }

        $script:linuxContainerRunTests | Where-Object {$_.SkipGssNtlmSspTests -ne $true} | ForEach-Object {
            $gssNtlmSspTestCases += @{
                Name = $_.Name
            }
        }
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
        it "Get PSVersion table from <Name> should be <ExpectedVersion>" -TestCases $runTestCases -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,

                [Parameter(Mandatory=$true)]
                [string]
                $ExpectedVersion
            )

            $actualVersion = Get-ContainerPowerShellVersion -TestContext $testContext -Name $Name
            $actualVersion | should -be $ExpectedVersion
        }

        it "Invoke-WebRequest from <Name> should not fail" -TestCases $webTestCases -Skip:($script:skipLinuxRun -or $webTestCases.count -eq 0) {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name
            )

            $metadataString = Get-MetadataUsingContainer -Name $Name
            $metadataString | Should -Not -BeNullOrEmpty
            $metadataJson = $metadataString | ConvertFrom-Json -ErrorAction Stop
            $metadataJson | Select-Object -ExpandProperty StableReleaseTag | Should -Match '^v\d+\.\d+\.\d+.*$'
        }

        it "Get-UICulture from <Name> should return en-US" -TestCases $runTestCases -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,

                [Parameter(Mandatory=$true)]
                [string]
                $ExpectedVersion
            )

            $culture = Get-UICultureUsingContainer -Name $Name
            $culture | Should -Not -BeNullOrEmpty
            $culture | Should -BeExactly 'en-US'
        }

        it "gss-ntlmssp is installed in <Name>" -TestCases $gssNtlmSspTestCases -Skip:($script:skipLinuxRun -or $gssNtlmSspTestCases.count -eq 0) {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name
            )

            $gssNtlmSspPath = Get-LinuxGssNtlmSsp -Name $Name
            $gssNtlmSspPath | Should -Not -BeNullOrEmpty
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
                ExpectedValue = "docker run $($_.ImageName)"
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

Describe "Windows Containers" -Tags 'Behavior', 'Windows' {
    BeforeAll{
        $testContext = Get-TestContext -type Windows
        $runTestCases = @()
        $script:windowsContainerRunTests | ForEach-Object {
            $runTestCases += @{
                Name = $_.Name
                ExpectedVersion = $_.ExpectedVersion
            }
        }

        $webTestCases = @()
        $script:windowsContainerRunTests | Where-Object {$_.SkipWebCmdletTests -ne $true} | ForEach-Object {
            $webTestCases += @{
                Name = $_.Name
            }
        }
    }
    BeforeEach {
        Remove-Item $testContext.resolvedXmlPath -ErrorAction SilentlyContinue
        Remove-Item $testContext.resolvedLogPath -ErrorAction SilentlyContinue
    }

    Context "Run Powershell" {
        it "Get PSVersion table from <Name> should be <ExpectedVersion>" -TestCases $runTestCases -skip:$script:skipWindowsRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,

                [Parameter(Mandatory=$true)]
                [string]
                $ExpectedVersion
            )

            Get-ContainerPowerShellVersion -TestContext $testContext -Name $Name | should -be $ExpectedVersion
        }

        it "Invoke-WebRequest from <Name> should not fail" -TestCases $webTestCases -skip:$script:skipWindowsRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name
            )

            $metadataString = Get-MetadataUsingContainer -Name $Name
            $metadataString | Should -Not -BeNullOrEmpty
            $metadataJson = $metadataString | ConvertFrom-Json -ErrorAction Stop
            $metadataJson | Select-Object -ExpandProperty StableReleaseTag | Should -Match '^v\d+\.\d+\.\d+.*$'
        }

        it "Path of <Name> should match the base container" -TestCases $webTestCases -skip:$script:skipWindowsRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name
            )

            $path = Get-ContainerPath -Name $Name

            #TODO: Run the base image and make sure the path is included

            $path | should -Match ([System.Text.RegularExpressions.Regex]::Escape("C:\Windows\system32"))
        }
    }

    Context "Labels" {
        $labelTestCases = @()
        $script:windowsContainerRunTests | ForEach-Object {
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
                ExpectedValue = "docker run $($_.ImageName)"
                Expectation = 'BeExactly'
            }
        }

        it "Image <Name> should have label: <Label>, with value: <ExpectedValue>" -TestCases $labelTestCases -Skip:$script:skipWindowsRun {
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
