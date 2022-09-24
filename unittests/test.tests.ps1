Describe "build.ps1 -Test" {
    BeforeAll {
        $relativeRepoRoot = Join-Path $PSScriptRoot ".."
        $repoRoot = (Resolve-Path -Path $relativeRepoRoot).ProviderPath
        Write-Verbose "repoRoot: $repoRoot"
        $buildScript = Join-Path $repoRoot "build.ps1"
        Write-Verbose "buildScript: $buildScript"
        Import-Module -Name "$repoRoot/tools/buildHelper/buildHelper.psm1" -Force

        # get versions for current preview and stable channel
        $previewVersion = Get-PowerShellVersion -Preview
        $stableVersion = Get-PowerShellVersion

        Mock -CommandName "Invoke-PesterWrapper" -MockWith {
            Write-Verbose "Mocking Invoke-PesterWrapper" -Verbose
        } -ParameterFilter { $ExtraParams -ne $null}
    }
    Context "-Channel -Name" {
        It "Should invoke pester" {
            & $buildScript -Test -Pull -ImageName "unittest" -Name 'ubuntu22.04' -Channel preview -Version $previewVersion 4>&1 | out-null
            Assert-VerifiableMock
        }
        It "throw for non existant image" {
            [Type] $exceptionType = [System.Management.Automation.ParameterBindingException]
            {& $buildScript -Test -Pull -ImageName "unittest" -Name 'doesnt exist' -Channel preview -Version $previewVersion 4>&1} | Should -Throw -ExceptionType $exceptionType
            Assert-VerifiableMock
        }
    }
    Context "-channel -all" {
        It "Should invoke pester" {
            & $buildScript -Test -channel stable -all -Version $stableVersion 4>&1 | out-null
            Assert-VerifiableMock
        }
    }
}
