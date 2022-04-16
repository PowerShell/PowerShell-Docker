Describe "build.ps1 -GenerateManifestLists" {
    BeforeAll {
        Get-Module -Name "buildHelper" | Remove-Module -Force
        $relativeRepoRoot = Join-Path $PSScriptRoot ".."
        $repoRoot = (Resolve-Path -Path $relativeRepoRoot).ProviderPath
        Write-Verbose "repoRoot: $repoRoot"
        $buildScript = Join-Path $repoRoot "build.ps1"
        Write-Verbose "buildScript: $buildScript"
    }

    It "Should not throw" {
        $json = & $buildScript -GenerateManifestLists -Channel stable -OsFilter All 4>$null
        $json | Should -Not -BeNullOrEmpty
        $json | ConvertFrom-Json -AsHashtable | Should -Not -BeNullOrEmpty
    }
}
