Describe "build.ps1 -GenerateMatrixJson" {
    BeforeAll {
        Get-Module -Name "buildHelper" | Remove-Module -Force
        $relativeRepoRoot = Join-Path $PSScriptRoot ".."
        $repoRoot = (Resolve-Path -Path $relativeRepoRoot).ProviderPath
        Write-Verbose "repoRoot: $repoRoot"
        $buildScript = Join-Path $repoRoot "build.ps1"
        Write-Verbose "buildScript: $buildScript"
        Import-Module -Name "$repoRoot/tools/buildHelper" -Scope Global
    }
    Context "By channel" {
        BeforeAll {
            $script:imageTestCases = @()
            [string[]]$global:writeHostBuffer = @()
            function Write-Host {
                param(
                    [object]$Object
                )
                Write-Verbose "got write-Host" -Verbose
                $global:writeHostBuffer += $Object.ToString()
            }
            $global:matrixValue = @()
            Mock -CommandName "Set-BuildVariable" -MockWith {
                $global:matrixValue += [pscustomobject]@{
                    Value=$Value
                    Name=$Name
                }
                Write-Verbose "Mocking Set-BuildVariable" -Verbose
            }

        }
        BeforeEach {
            $Channel = 'stable'
            $pattern = '##vso\[task\.setvariable variable=matrix_'+$Channel+'_(windows|linux);isoutput=true]'
        }
        It "Should Set matrix" {
            $vstsCmd = & $buildScript -GenerateMatrixJson -Channel $Channel 4>$null
            Assert-MockCalled -CommandName "Set-BuildVariable" -Times 1
        }
        It "Should have generated valid json" {
            $script:matrix = @()
            foreach($vstsVariable in $global:matrixValue) {
                $json = $vstsVariable.Value
                { $script:matrix += $json | ConvertFrom-Json -AsHashtable } | should -not -Throw
            }
            $script:matrix.count | Should -Be 4
        }
        It "Should have multiple images" {
            foreach($platforMatrix in $Script:matrix) {
                Write-Verbose "platform: $platforMatrix"
                $platforMatrix.Keys.count | Should -BeGreaterThan
                foreach($key in $platforMatrix.Keys) {
                    $image = $platforMatrix[$key]
                    $script:imageTestCases += ($image)
                }
            }
        }

        It "<ImageName> Should have all its properties" -TestCases $imageTestCases {
            param(
                $ImageName,
                $ContinueOnError,
                $OsVersion,
                $DistributionState,
                $EndOfLife,
                $Channel,
                $JobName
            )

            $ImageName          | Should -Not -BeNullOrEmpty
            $ContinueOnError    | Should -BeOfType [bool]
            $OsVersion          | Should -Not -BeNullOrEmpty
            $DistributionState  | Should -Match '^(unknown|validated|validating|endoflife)$'
            $EndOfLife          | Should -BeOfType [datetime]
            $Channel            | Should -Be $Channel
            $JobName            | Should -Match '^[^ \-]+$'
        }
    }
    Context "Full matrix Json" {
        BeforeAll {
            $script:imageTestCases = @()
        }
        BeforeEach {
            $pattern = '##vso\[task\.setvariable variable=matrix_'+$Channel+'_(windows|linux);isoutput=true]'
        }
        It "Should generate json" {
            $json = & $buildScript -GenerateMatrixJson -FullJson 4>$null
            $script:matrix = @()
            $script:matrix = $json | ConvertFrom-Json -AsHashtable
            $script:matrix.Keys.count | Should -BeGreaterThan 2
        }

        It "Should have multiple images" {
            foreach($platforMatrix in $Script:matrix) {
                Write-Verbose "platform: $platforMatrix"
                $platforMatrix.Keys.count | Should -BeGreaterThan
                foreach($key in $platforMatrix.Keys) {
                    $image = $platforMatrix[$key]
                    $script:imageTestCases += ($image)
                }
            }
        }

        It "<Channel>-<ImageName> Should have all its properties" -TestCases $imageTestCases {
            param(
                $ImageName,
                $ContinueOnError,
                $OsVersion,
                $DistributionState,
                $EndOfLife,
                $Channel,
                $JobName
            )

            $ImageName          | Should -Not -BeNullOrEmpty
            $ContinueOnError    | Should -BeOfType [bool]
            $OsVersion          | Should -Not -BeNullOrEmpty
            $DistributionState  | Should -Match '^(unknown|validated|validating|endoflife)$'
            $EndOfLife          | Should -BeOfType [datetime]
            $Channel            | Should -Be $Channel
            $JobName            | Should -Match '^[^ \-]+$'
        }
    }
}
