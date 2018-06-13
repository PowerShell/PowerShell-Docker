# A wrapper to ensure that we upload test results
# and that if we are not able to that it does not fail
# the CI build
function Update-AppVeyorTestResults
{
    param(
        [string] $resultsFile
    )

    if($env:APPVEYOR)
    {
        $retryCount = 0
        $pushedResults = $false
        $pushedArtifacts = $false
        while( (!$pushedResults -or !$pushedResults) -and $retryCount -lt 3)
        {
            if($retryCount -gt 0)
            {
                Write-Verbose "Retrying updating test artifacts..."
            }

            $retryCount++
            $resolvedResultsPath = (Resolve-Path $resultsFile)
            try {
                (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", $resolvedResultsPath)
                $pushedResults = $true
            }
            catch {
                Write-Warning "Pushing test result failed..."
            }

            try {
                Push-AppveyorArtifact $resolvedResultsPath
                $pushedArtifacts = $true
            }
            catch {
                Write-Warning "Pushing test Artifact failed..."
            }
        }

        if(!$pushedResults -or !$pushedResults)
        {
            Write-Warning "Failed to push all artifacts for $resultsFile"
        }
    }
    else
    {
        Write-Warning "Not running in appveyor, skipping upload of test results: $resultsFile"
    }
}
