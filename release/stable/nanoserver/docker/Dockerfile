# escape=`
# Args used by from statements must be defined here:
ARG fromTag=1709
ARG WindowsServerCoreVersion=latest
ARG WindowsServerCoreRepo=mcr.microsoft.com/windows/servercore
ARG NanoServerRepo=mcr.microsoft.com/windows/nanoserver

# Use server core as an installer container to extract PowerShell,
# As this is a multi-stage build, this stage will eventually be thrown away
FROM ${WindowsServerCoreRepo}:$WindowsServerCoreVersion  AS installer-env

# Arguments for installing PowerShell, must be defined in the container they are used
ARG PS_VERSION=6.1.0

ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v$PS_VERSION/PowerShell-$PS_VERSION-win-x64.zip
ARG PS_PACKAGE_URL_BASE64

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN if (!($env:PS_VERSION -match '^\d+\.\d+\.\d+(-\w+(\.\d+)?)?$' )) { `
        throw ('PS_Version ({0}) must match the regex "^\d+\.\d+\.\d+(-\w+(\.\d+)?)?$"' -f $env:PS_VERSION) `
    } `
    if($env:PS_PACKAGE_URL_BASE64){ `
        Write-host "decoding: $env:PS_PACKAGE_URL_BASE64" `
        $url = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($env:PS_PACKAGE_URL_BASE64)) `
    } else { `
        Write-host "using url: $env:PS_PACKAGE_URL" `
        $url = $env:PS_PACKAGE_URL `
    } `
    Write-host "downloading: $url" `
    Invoke-WebRequest -Uri $url -outfile /powershell.zip

RUN Expand-Archive powershell.zip -DestinationPath \PowerShell

# Install PowerShell into NanoServer
FROM ${NanoServerRepo}:${fromTag}

ARG VCS_REF="none"
ARG PS_VERSION=6.1.0
ARG IMAGE_NAME=mcr.microsoft.com/powershell

LABEL maintainer="PowerShell Team <powershellteam@hotmail.com>" `
      readme.md="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" `
      description="This Dockerfile will install the latest release of PowerShell." `
      org.label-schema.usage="https://github.com/PowerShell/PowerShell/tree/master/docker#run-the-docker-image-you-built" `
      org.label-schema.url="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" `
      org.label-schema.vcs-url="https://github.com/PowerShell/PowerShell-Docker" `
      org.label-schema.name="powershell" `
      org.label-schema.vcs-ref=${VCS_REF} `
      org.label-schema.vendor="PowerShell" `
      org.label-schema.version=${PS_VERSION} `
      org.label-schema.schema-version="1.0" `
      org.label-schema.docker.cmd="docker run ${IMAGE_NAME} pwsh -c '$psversiontable'" `
      org.label-schema.docker.cmd.devel="docker run ${IMAGE_NAME}" `
      org.label-schema.docker.cmd.test="docker run ${IMAGE_NAME} pwsh -c Invoke-Pester" `
      org.label-schema.docker.cmd.help="docker run ${IMAGE_NAME} pwsh -c Get-Help"

# Copy PowerShell Core from the installer container
ENV ProgramFiles C:\Program Files
COPY --from=installer-env ["\\PowerShell\\", "$ProgramFiles\\PowerShell"]

# Persist %PSCORE% ENV variable for user convenience
ENV PSCORE="$ProgramFiles\PowerShell\pwsh.exe"

# Set the path
RUN setx PATH "%PATH%;%ProgramFiles%\PowerShell"

CMD ["pwsh.exe"]
