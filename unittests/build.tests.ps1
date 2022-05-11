Describe "buildps1-Build" {
    BeforeAll {
        $relativeRepoRoot = Join-Path $PSScriptRoot ".."
        $repoRoot = (Resolve-Path -Path $relativeRepoRoot).ProviderPath
        Write-Verbose "repoRoot: $repoRoot"
        $buildScript = Join-Path $repoRoot "build.ps1"
        Write-Verbose "buildScript: $buildScript"
        Import-Module -Name "$repoRoot/tools/buildHelper/buildHelper.psm1" -Force
        Mock -CommandName "Invoke-PesterWrapper" -MockWith {
            Write-Verbose "Mocking Invoke-PesterWrapper" -Verbose
        } -ParameterFilter { $ExtraParams -ne $null}
        Mock -CommandName "Set-BuildVariable" -MockWith {
            Write-Verbose "Mocking Set-BuildVariable" -Verbose
        } -ParameterFilter { $ExtraParams -ne $null}
    }
    Context "-Channel -Name" {
        It "Should invoke pester" {
            & $buildScript -Build -Name "mariner1" -Channel preview 4>&1 | out-null
            Assert-MockCalled -CommandName "Invoke-PesterWrapper" -Times 1
            Assert-MockCalled -CommandName "Set-BuildVariable" -Times 1
        }

        It "throw if name doesn't exist" {
            [Type] $exceptionType = [System.Management.Automation.ParameterBindingException]
            {& $buildScript -Build -Name "doesntexist" -Channel preview 4>&1 } | Should -Throw -ExceptionType $exceptionType
        }
    }
    Context "-channel -all" {
        It "Should invoke pester" {
            & $buildScript -Build -channel stable -all 4>&1 | out-null
            Assert-MockCalled -CommandName "Invoke-PesterWrapper" -Times 1
        }
    }
}
