# escape=`
ARG fromTag=latest
ARG WindowsServerCoreRepo=mcr.microsoft.com/windows/servercore

# Use server core as an installer container to extract PowerShell,
# As this is a multi-stage build, this stage will eventually be thrown away
FROM ${WindowsServerCoreRepo}:${fromTag} AS installer-env

ARG PS_VERSION=6.2.0
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/PowerShell-${PS_VERSION}-win-x64.zip

SHELL ["C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe", "-command"]

ARG PS_PACKAGE_URL_BASE64

RUN Write-host "Verifying valid Version..."; `
    if (!($env:PS_VERSION -match '^\d+\.\d+\.\d+(-\w+(\.\d+)?)?$' )) { `
        throw ('PS_Version ({0}) must match the regex "^\d+\.\d+\.\d+(-\w+(\.\d+)?)?$"' -f $env:PS_VERSION) `
    } `
    $ProgressPreference = 'SilentlyContinue'; `
    if($env:PS_PACKAGE_URL_BASE64){ `
        Write-host "decoding: $env:PS_PACKAGE_URL_BASE64" ;`
        $url = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($env:PS_PACKAGE_URL_BASE64)) `
    } else { `
        Write-host "using url: $env:PS_PACKAGE_URL" ;`
        $url = $env:PS_PACKAGE_URL `
    } `
    Write-host "downloading: $url"; `
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; `
    Invoke-WebRequest -Uri $url -outfile /powershell.zip -verbose; `
    Expand-Archive powershell.zip -DestinationPath  \PowerShell

# Install PowerShell into WindowsServerCore
FROM ${WindowsServerCoreRepo}:${fromTag}

# Copy PowerShell Core from the installer container
ENV ProgramFiles="C:\Program Files" `
    # set a fixed location for the Module analysis cache
    LOCALAPPDATA="C:\Users\ContainerAdministrator\AppData\Local" `
    PSModuleAnalysisCachePath="$LOCALAPPDATA\Microsoft\Windows\PowerShell\docker\ModuleAnalysisCache" `
    # Persist %PSCORE% ENV variable for user convenience
    PSCORE="$ProgramFiles\PowerShell\pwsh.exe" `
    POWERSHELL_DISTRIBUTION_CHANNEL="PSDocker-WindowsServerCore-${fromTag}"

# Copy PowerShell Core from the installer container
COPY --from=installer-env ["\\PowerShell\\", "$ProgramFiles\\PowerShell\\latest"]

# Set the path
RUN setx /M PATH "%ProgramFiles%\PowerShell\latest;%PATH%;"

# intialize powershell module cache
RUN pwsh `
        -NoLogo `
        -NoProfile `
        -Command " `
          \$Env:POWERSHELL_TELEMETRY_OPTOUT=1; \
          $stopTime = (get-date).AddMinutes(15); `
          $ErrorActionPreference = 'Stop' ; `
          $ProgressPreference = 'SilentlyContinue' ; `
          while(!(Test-Path -Path $env:PSModuleAnalysisCachePath)) {  `
            Write-Host "'Waiting for $env:PSModuleAnalysisCachePath'" ; `
            if((get-date) -gt $stopTime) { throw 'timout expired'} `
            Start-Sleep -Seconds 6 ; `
          }"

CMD ["pwsh.exe"]
