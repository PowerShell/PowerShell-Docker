# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Import-module -Name "$PSScriptRoot\containerTestCommon.psm1" -Force
$script:linuxContainerBuildTests = Get-LinuxContainer -Purpose 'Build'
$script:windowsContainerBuildTests = Get-WindowsContainer -Purpose 'Build'
$script:linuxContainerRunTests = Get-LinuxContainer -Purpose 'Verification'
$script:windowsContainerRunTests = Get-WindowsContainer -Purpose 'Verification'
$script:skipLinux = (Test-SkipLinux) -or !$script:linuxContainerBuildTests
$script:skipWindows = (Test-SkipWindows) -or !$script:windowsContainerBuildTests
$script:skipLinuxRun = (Test-SkipLinux) -or !$script:linuxContainerRunTests
$script:skipWindowsRun = (Test-SkipWindows) -or !$script:windowsContainerRunTests

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

        foreach($tag in $Tags)
        {
            $buildArgList += @(
                "-t"
                $tag
            )
        }

        Invoke-Docker -Command build -Params @(
                '--pull'
                '--quiet'
                $buildArgList
                $path 
            ) -SuppressHostOutput
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

        foreach($tag in $Tags)
        {
            $buildArgList += @(
                "-t"
                $tag
            )
        }

        Invoke-Docker -Command build -Params @(
                '--pull'
                '--quiet'
                $buildArgList
                $path 
            ) -SuppressHostOutput
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
    It "<Name> pushes without error" -TestCases $script:linuxContainerRunTests -Skip:$script:skipLinuxRun {
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

        foreach($tag in $tags) {
            Invoke-Docker -Command push -Params @(
                    ${tag}
                ) -SuppressHostOutput
        }
    }
}

Describe "Push Windows Containers" -Tags 'Windows', 'Push' {
    it "<Name> Pushes without error" -TestCases $script:windowsContainerRunTests  -skip:$script:skipWindowsRun {
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

        foreach($tag in $tags) {
            Invoke-Docker -Command push -Params @(
                    ${tag}
                ) -SuppressHostOutput
        }
    }
}
