Describe "build.ps1 -CheckForDuplicateTags" {
    BeforeAll {
        Get-Module -Name "buildHelper" | Remove-Module -Force
        $relativeRepoRoot = Join-Path $PSScriptRoot ".."
        $repoRoot = (Resolve-Path -Path $relativeRepoRoot).ProviderPath
        Write-Verbose "repoRoot: $repoRoot"
        $buildScript = Join-Path $repoRoot "build.ps1"
        Write-Verbose "buildScript: $buildScript"
    }

    It "Should not throw" {
        $verboseLog = & $buildScript -CheckForDuplicateTags -Channel stable, lts, preview 4>&1
        $verboseLog | Should -Not -BeNullOrEmpty
    }
}
