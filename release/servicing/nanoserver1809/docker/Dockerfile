# escape=`
# Args used by from statements must be defined here:
ARG fromTag=1709
ARG InstallerVersion=nanoserver
ARG InstallerRepo=mcr.microsoft.com/powershell
ARG NanoServerRepo=mcr.microsoft.com/windows/nanoserver

# Use server core as an installer container to extract PowerShell,
# As this is a multi-stage build, this stage will eventually be thrown away
FROM ${InstallerRepo}:$InstallerVersion  AS installer-env

# Arguments for installing PowerShell, must be defined in the container they are used
ARG PS_VERSION=6.2.0

ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v$PS_VERSION/PowerShell-$PS_VERSION-win-x64.zip

SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

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
    New-Item -ItemType Directory /installer > $null ; `
    Invoke-WebRequest -Uri $url -outfile /installer/powershell.zip -verbose; `
    Expand-Archive /installer/powershell.zip -DestinationPath \PowerShell

# Install PowerShell into NanoServer
FROM ${NanoServerRepo}:${fromTag}

# Copy PowerShell Core from the installer container
ENV ProgramFiles="C:\Program Files" `
    # set a fixed location for the Module analysis cache
    LOCALAPPDATA="C:\Users\ContainerAdministrator\AppData\Local" `
    PSModuleAnalysisCachePath="$LOCALAPPDATA\Microsoft\Windows\PowerShell\docker\ModuleAnalysisCache" `
    # Persist %PSCORE% ENV variable for user convenience
    PSCORE="$ProgramFiles\PowerShell\pwsh.exe" `
    # Set the default windows path so we can use it
    WindowsPATH="C:\Windows\system32;C:\Windows"

### Begin workaround ###
# Note that changing user on nanoserver is not recommended
# See, https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/container-base-images#base-image-differences
# But we are working around a bug introduced in the nanoserver image introduced in 1809
# Without this, PowerShell Direct will fail
# this command sholud be like this: https://github.com/PowerShell/PowerShell-Docker/blob/f81009c42c96af46aef81eb1515efae0ef29ad5f/release/preview/nanoserver/docker/Dockerfile#L76
USER ContainerAdministrator

# This is basically the correct code except for the /M
RUN setx PATH "%PATH%;%ProgramFiles%\PowerShell;" /M

USER ContainerUser
### End workaround ###

COPY --from=installer-env ["\\PowerShell\\", "$ProgramFiles\\PowerShell"]

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
