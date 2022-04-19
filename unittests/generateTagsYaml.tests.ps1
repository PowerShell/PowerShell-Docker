Describe "build.ps1 -GenerateTagsYaml" {
    BeforeAll {
        Get-Module -Name "buildHelper" | Remove-Module -Force
        $relativeRepoRoot = Join-Path $PSScriptRoot ".."
        $repoRoot = (Resolve-Path -Path $relativeRepoRoot).ProviderPath
        Write-Verbose "repoRoot: $repoRoot"
        $buildScript = Join-Path $repoRoot "build.ps1"
        Write-Verbose "buildScript: $buildScript"
    }

    It "Should generate tags.yaml" {
        $yaml = & $buildScript -GenerateTagsYaml -Channel stable, lts, preview 4>$null
        $yaml | Should -Not -BeNullOrEmpty
    }
}
