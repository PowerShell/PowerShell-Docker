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
                UseAcr = [bool]$_.UseAcr
            }
        }
    }

    it "can build image <Name> from '<path>' - UseAcr:<UseAcr>" -TestCases $buildTestCases -Skip:$script:skipLinux {
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
            $SkipPull,

            [bool]
            $UseAcr
        )

        Invoke-DockerBuild -Tags $Tags -Path $Path -BuildArgs $BuildArgs -OSType linux -SkipPull:$SkipPull -UseAcr:$UseAcr
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

    it "can build image <Name> from '<path>'" -TestCases $buildTestCases -skip:$script:skipWindows {
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

        Invoke-DockerBuild -Tags $Tags -Path $Path -BuildArgs $BuildArgs -OSType windows -SkipPull:$SkipPull -UseAcr
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
            $Arm32 = [bool] $_.TestProperties.Arm32
            $runTestCases += @{
                Name = $_.Name
                ExpectedVersion = $_.ExpectedVersion
                Channel = $_.Channel
                Arm32 = $Arm32
            }
        }

        $webTestCases = @()
        $script:linuxContainerRunTests | Where-Object {$_.SkipWebCmdletTests -ne $true} | ForEach-Object {
            $Arm32 = [bool] $_.TestProperties.Arm32
            $webTestCases += @{
                Name = $_.Name
                Arm32 = $Arm32
            }
        }

        $gssNtlmSspTestCases = @()
        $script:linuxContainerRunTests | Where-Object {$_.SkipGssNtlmSspTests -ne $true} | ForEach-Object {
            $Arm32 = [bool] $_.TestProperties.Arm32
            $gssNtlmSspTestCases += @{
                Name = $_.Name
                Arm32 = $Arm32
            }
        }
    }
    AfterAll {
        # prune unused volumes
        $null=Invoke-Docker -Command 'volume', 'prune' -Params '--force' -SuppressHostOutput
    }
    BeforeEach {
        Remove-Item $testContext.resolvedXmlPath -ErrorAction SilentlyContinue
        Remove-Item $testContext.resolvedLogPath -ErrorAction SilentlyContinue
    }

    Context "Run Powershell" {
        it "PSVersion table from <Name> should contain <ExpectedVersion>" -TestCases $runTestCases -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,

                [Parameter(Mandatory=$true)]
                [string]
                $ExpectedVersion,

                [Parameter(Mandatory=$true)]
                [string]
                $Channel,

                [Bool]
                $Arm32
            )

            if($Arm32)
            {
                Set-ItResult -Pending -Because "Arm32 is falky on QEMU"
            }

            $actualVersion = Get-ContainerPowerShellVersion -TestContext $testContext -Name $Name
            $actualVersion | should -be $ExpectedVersion
        }

        it "Invoke-WebRequest from <Name> should not fail" -TestCases $webTestCases -Skip:($script:skipLinuxRun -or $webTestCases.count -eq 0) {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,

                [Bool]
                $Arm32
            )

            if($Arm32)
            {
                Set-ItResult -Pending -Because "Arm32 is falky on QEMU"
            }

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
                $ExpectedVersion,

                [Parameter(Mandatory=$true)]
                [string]
                $Channel,

                [Bool]
                $Arm32
            )

            if($Arm32)
            {
                Set-ItResult -Pending -Because "Arm32 is falky on QEMU"
            }

            $culture = Get-UICultureUsingContainer -Name $Name
            $culture | Should -Not -BeNullOrEmpty
            $culture | Should -BeExactly 'en-US'
        }

        it "gss-ntlmssp is installed in <Name>" -TestCases $gssNtlmSspTestCases -Skip:($script:skipLinuxRun -or $gssNtlmSspTestCases.count -eq 0) {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,

                [Bool]
                $Arm32
            )

            if($Arm32)
            {
                Set-ItResult -Pending -Because "Arm32 is falky on QEMU"
            }

            $gssNtlmSspPath = Get-LinuxGssNtlmSsp -Name $Name
            $gssNtlmSspPath | Should -Not -BeNullOrEmpty
        }

        it "Has POWERSHELL_DISTRIBUTION_CHANNEL environment variable defined" -TestCases $runTestCases -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,

                [Parameter(Mandatory=$true)]
                [string]
                $ExpectedVersion,

                [Parameter(Mandatory=$true)]
                [string]
                $Channel,

                [Bool]
                $Arm32
            )

            if($Arm32)
            {
                Set-ItResult -Pending -Because "Arm32 is falky on QEMU"
            }

            if ($Channel -ne 'preview') {
                Set-ItResult -Skipped -Because "Test is not applicable to $Channel"
            }

            $psDistChannel = Get-PowerShellDistibutionChannel -TestContext $testContext -Name $Name
            $psDistChannel | Should -BeLike "PSDocker-*"
        }
    }

    Context "permissions" {
        BeforeAll {
            $permissionsTestCases = @(
                $script:linuxContainerRunTests | ForEach-Object {
                    $path = '/opt/microsoft/powershell/6/pwsh'
                    switch -RegEx ($_.Channel)
                    {
                        'stable' {
                            $path = '/opt/microsoft/powershell/7/pwsh'
                        }
                        'lts' {
                            $path = '/opt/microsoft/powershell/7-lts/pwsh'
                        }
                        'preview' {
                            $path = '/opt/microsoft/powershell/7-preview/pwsh'
                        }
                    }

                    $Arm32 = [bool] $_.TestProperties.Arm32
                    @{
                        Name = $_.Name
                        Channel = $_.Channel
                        Arm32 = $Arm32
                        Path = $path
                    }
                }
            )
        }

        it "pwsh should be at <Path> in <channel>-<Name>" -TestCases $permissionsTestCases -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,
                [string]
                $Channel,

                [Bool]
                $Arm32,

                [string]
                $Path
            )

            if($Arm32)
            {
                Set-ItResult -Pending -Because "Arm32 is flaky on QEMU"
            }

            $paths = @(Get-DockerCommandSource -Name $name -Command 'pwsh')
            $paths.count | Should -BeGreaterOrEqual 1
            $pwshPath = $paths | Where-Object { $_ -like '*microsoft*' }
            $pwshPath | Should -Be $Path
        }

        it "pwsh should have execute permissions for all in <channel>-<Name>" -TestCases $permissionsTestCases -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,
                [string]
                $Channel,

                [Bool]
                $Arm32,

                [string]
                $Path
            )

            if($Arm32)
            {
                Set-ItResult -Pending -Because "Arm32 is falky on QEMU"
            }

            $permissions = Get-DockerImagePwshPermissions -Name $name -Path $path
            $permissions | Should -Match '^[\-rw]{3}x([\-rw]{2}x){2}$' -Because 'Everyone should be able to execute'
        }

        it "pwsh should NOT have write permissions for others in <channel>-<Name>" -TestCases $permissionsTestCases -Skip:$script:skipLinuxRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,
                [string]
                $Channel,

                [Bool]
                $Arm32,

                [string]
                $Path
            )

            if($Arm32)
            {
                Set-ItResult -Pending -Because "Arm32 is falky on QEMU"
            }

            $permissions = Get-DockerImagePwshPermissions -Name $name -Path $path
            $permissions | Should -Match '^[\-rwx]{4}[\-rwx]{3}[\-rx]{3}$' -Because 'Others should not be able to write'
        }
    }

    Context "default executables" {
        BeforeAll {
            #apt-utils ca-certificates curl wget apt-transport-https locales gnupg2 inetutils-ping git sudo less procps
            $commands = @(
                #'locale-gen'
                # debian 'update-ca-certificates'
                'less'
            )

            $testdepsTestCases = @()
            $script:linuxContainerRunTests | ForEach-Object {
                $Arm32 = [bool] $_.TestProperties.Arm32
                $name = $_.Name
                foreach($command in $commands)
                {
                    $testdepsTestCases += @{
                        Name = $name
                        Command = $command
                        Arm32 = $Arm32
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
                $Command,

                [Bool]
                $Arm32
            )

            if($Arm32)
            {
                Set-ItResult -Pending -Because "Arm32 is falky on QEMU"
            }

            $source = Get-DockerCommandSource -Name $name -command $Command
            $source | Should -Not -BeNullOrEmpty
        }
    }

    Context "test-deps" {
        BeforeAll{
            #apt-utils ca-certificates curl wget apt-transport-https locales gnupg2 inetutils-ping git sudo less procps
            $commands = @(
                #@{command = 'adduser'}
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
                @{command = 'openssl'}
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
        BeforeAll {
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

            if ($env:DOCKER_RELEASE) {
                Set-ItResult -Skipped -Because "Test only used in CI"
            }

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
                Channel = $_.Channel
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
                $ExpectedVersion,

                [Parameter(Mandatory=$true)]
                [string]
                $Channel
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

        it "Has POWERSHELL_DISTRIBUTION_CHANNEL environment variable defined" -TestCases $runTestCases -Skip:$script:skipWindowsRun {
            param(
                [Parameter(Mandatory=$true)]
                [string]
                $name,

                [Parameter(Mandatory=$true)]
                [string]
                $ExpectedVersion,

                [Parameter(Mandatory=$true)]
                [string]
                $Channel
            )

            if ($Channel -ne 'preview') {
                Set-ItResult -Skipped -Because "Test is not applicable to $Channel"
            }

            $psDistChannel = Get-PowerShellDistibutionChannel -TestContext $testContext -Name $Name
            $psDistChannel | Should -BeLike "PSDocker-*"
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
                UseAcr = [bool]$_.UseAcr
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
            $Tags,

            [switch]
            $UseAcr
        )

        if($env:ACR_NAME -and $UseAcr.IsPresent)
        {
            Set-ItResult -Pending -Because "Image is missing when building using ACR"
        }

        foreach($tag in $tags) {
            Invoke-Docker -Command push -Params @(
                    ${tag}
                ) -SuppressHostOutput
        }
    }
}

Describe "Push Windows Containers" -Tags 'Windows', 'Push' {
    BeforeAll {
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
