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

    It "Each tag should only be in one channel" {
        $json = & $buildScript -GenerateManifestLists -Channel stable, preview, lts -OsFilter All | ConvertFrom-Json
        $tags = @{}
        $json | ForEach-Object {
            $channel = $_.channel
            foreach ($tag in $_.tags) {
                if (!$tags.ContainsKey($tag)) {
                    $tags[$tag] = @()
                }
                if ($tags[$tag] -notcontains $channel) {
                    $tags[$tag] += $channel
                }
            }
        }

        foreach($tag in $tags.Keys) {
            $tags.$tag.count | should -Be 1 -Because "$Tag should not be in multiple channels ($($tags.$tag))"
        }
    }
}
