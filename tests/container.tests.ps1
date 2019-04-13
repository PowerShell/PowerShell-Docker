# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
Set-StrictMode -Off

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
                SkipPull = $_.SkipPull
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
            $BuildArgs,

            [bool]
            $SkipPull
        )

        Invoke-DockerBuild -Tags $Tags -Path $Path -BuildArgs $BuildArgs -OSType linux -SkipPull:$SkipPull
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
                SkipPull = $_.SkipPull
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
            $BuildArgs,

            [bool]
            $SkipPull
        )

        Invoke-DockerBuild -Tags $Tags -Path $Path -BuildArgs $BuildArgs -OSType windows -SkipPull:$SkipPull
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

        $gssNtlmSspTestCases = @()
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
        BeforeAll {
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

            $script:linuxContainerRunTests | Where-Object { $_.OptionalTests -contains 'test-deps-musl' } | ForEach-Object {
                $labelTestCases += @{
                    Name = $_.Name
                    Label = 'com.azure.dev.pipelines.agent.handler.node.path'
                    ExpectedValue = "/usr/local/bin/node"
                    Expectation = 'BeExactly'
                }
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

    Context "default executables" {
        BeforeAll{
            #apt-utils ca-certificates curl wget apt-transport-https locales gnupg2 inetutils-ping git sudo less procps
            $commands = @(
                'locale-gen'
                'update-ca-certificates'
                'openssl'
                'less'
            )

            $testdepsTestCases = @()
            $script:linuxContainerRunTests | ForEach-Object {
                $name = $_.Name
                foreach($command in $commands)
                {
                    $testdepsTestCases += @{
                        Name = $name
                        Command = $command
                    }
                }
            }

        }

        it "<Name> should have <command>" -TestCases $testdepsTestCases -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,
                [Parameter(Mandatory=$true)]
                [string]
                $Command
            )

            $source = Get-DockerCommandSource -Name $name -command $Command
            $source | Should -Not -BeNullOrEmpty
        }
    }

    Context "test-deps" {
        BeforeAll{
            #apt-utils ca-certificates curl wget apt-transport-https locales gnupg2 inetutils-ping git sudo less procps
            $commands = @(
                @{command = 'adduser'}
                @{command = 'bash'}
                @{command = 'curl'}
                @{command = 'find'}
                @{command = 'hostname'}
                @{command = 'ping'}
                @{command = 'ps'}
                @{command = 'su'}
                @{command = 'sudo'}
                @{command = 'tar'}
                @{command = 'wget'}
            )

            $debianCommands = @(
                @{command = 'apt'}
                @{command = 'apt-get'}
            )

            $muslCommands = @(
                @{
                    command = 'node'
                    path = '/usr/local/bin/node'
                }
            )

            $testdepsTestCases = @()
            $script:linuxContainerRunTests | Where-Object { $_.OptionalTests -contains 'test-deps' } | ForEach-Object {
                $name = $_.Name
                foreach($command in $commands)
                {
                    $testdepsTestCases += @{
                        Name = $name
                        Command = $command.command
                        ExpectedPath = $command.Path
                    }
                }
            }

            $script:linuxContainerRunTests | Where-Object { $_.OptionalTests -contains 'test-deps-debian' } | ForEach-Object {
                $name = $_.Name
                foreach($command in $debianCommands)
                {
                    $testdepsTestCases += @{
                        Name = $name
                        Command = $command.command
                        ExpectedPath = $command.Path
                    }
                }
            }

            $script:linuxContainerRunTests | Where-Object { $_.OptionalTests -contains 'test-deps-musl' } | ForEach-Object {
                $name = $_.Name
                foreach($command in $muslCommands)
                {
                    $testdepsTestCases += @{
                        Name = $name
                        Command = $command.command
                        ExpectedPath = $command.Path
                    }
                }
            }

            $skipTestDeps = $testdepsTestCases.count -eq 0
        }

        it "<Name> should have <command>" -TestCases $testdepsTestCases -Skip:$skipTestDeps {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,
                [Parameter(Mandatory=$true)]
                [string]
                $Command,
                [string]
                $ExpectedPath
            )

            $source = Get-DockerCommandSource -Name $name -command $Command
            $source | Should -Not -BeNullOrEmpty -Because "$command should be found"
            if($ExpectedPath)
            {
                $source | Should -BeExactly $ExpectedPath  -Because "$command should be at $ExpectedPath"
            }
        }
    }

    Context "Size" {
        BeforeAll{
            $sizeTestCases = @($script:linuxContainerRunTests | ForEach-Object {
                $size = $_.TestProperties.size
                @{
                    Name = $_.Name
                    ExpectedSize = $size
                }
            })
        }

        it "Verify size of <name>" -TestCases $sizeTestCases  -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,
                [int]$ExpectedSize
            )

            $sizeMb = Get-DockerImageSize -name $name
            Write-Verbose "image is $sizeMb MiB" -Verbose
            if($ExpectedSize -and !$env:RELEASE_DEFINITIONID)
            {
                # allow for a 5% increase without an error
                $sizeMb | Should -BeLessOrEqual ($ExpectedSize * 1.05) -Because "$name is set to be $ExpectedSize in meta.json"
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
