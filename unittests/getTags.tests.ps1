Describe "build.ps1 -GetTags" {
    BeforeAll {
        Get-Module -Name "buildHelper" | Remove-Module -Force
        $relativeRepoRoot = Join-Path $PSScriptRoot ".."
        $repoRoot = (Resolve-Path -Path $relativeRepoRoot).ProviderPath
        Write-Verbose "repoRoot: $repoRoot"
        $buildScript = Join-Path $repoRoot "build.ps1"
        Write-Verbose "buildScript: $buildScript"
    }

    Context "-Channel -Name" {
        It "Should invoke pester" {
            & $buildScript -GetTags -Name 'mariner1' -Channel preview -Version v7.2.2 4>&1 | out-null
        }
        It "throw for non existant image" {
            [Type] $exceptionType = [System.Management.Automation.ParameterBindingException]
            {& $buildScript -GetTags -Name 'doesnt exist' -Channel preview -Version v7.2.2 4>&1} | Should -Throw -ExceptionType $exceptionType
        }
    }
    Context "-channel -all" {
        It "Should invoke pester" {
            & $buildScript -GetTags -channel stable -all -Version v7.2.2 4>&1 | out-null
            Assert-VerifiableMock
        }
    }
}
