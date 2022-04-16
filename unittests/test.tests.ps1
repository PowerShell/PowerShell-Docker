Describe "build.ps1 -Test" {
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
    }
    Context "-Channel -Name" {
        It "Should invoke pester" {
            & $buildScript -Test -Pull -ImageName "unittest" -Name 'mariner1' -Channel preview -Version v7.2.2 4>&1 | out-null
            Assert-VerifiableMock
        }
        It "throw for non existant image" {
            [Type] $exceptionType = [System.Management.Automation.ParameterBindingException]
            {& $buildScript -Test -Pull -ImageName "unittest" -Name 'doesnt exist' -Channel preview -Version v7.2.2 4>&1} | Should -Throw -ExceptionType $exceptionType
            Assert-VerifiableMock
        }
    }
    Context "-channel -all" {
        It "Should invoke pester" {
            & $buildScript -Test -channel stable -all -Version v7.2.2 4>&1 | out-null
            Assert-VerifiableMock
        }
    }
}
