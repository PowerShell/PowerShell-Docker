# Docker image file that describes an Ubuntu18.04 image with PowerShell installed from Microsoft APT Repo
ARG fromTag=18.04
ARG imageRepo=ubuntu

FROM ${imageRepo}:${fromTag} AS installer-env

ARG PS_VERSION=6.2.0
ARG PS_PACKAGE=powershell_${PS_VERSION}-1.ubuntu.18.04_amd64.deb
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}

# Define ENVs for Localization/Globalization
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Ubuntu-18.04

# Install dependencies and clean up
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    # curl is required to grab the Linux package
        curl \
    # less is required for help in powershell
        less \
    # requied to setup the locale
        locales \
    # required for SSL
        ca-certificates \
        gss-ntlmssp \
    # Download the Linux package and save it
    && echo ${PS_PACKAGE_URL} \
    && curl -sSL ${PS_PACKAGE_URL} -o /tmp/powershell.deb \
    && apt-get install --no-install-recommends -y /tmp/powershell.deb \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen $LANG && update-locale \
    # remove powershell package
    && rm /tmp/powershell.deb \
    # intialize powershell module cache
    && pwsh \
        -NoLogo \
        -NoProfile \
        -Command " \
          \$ErrorActionPreference = 'Stop' ; \
          \$ProgressPreference = 'SilentlyContinue' ; \
          while(!(Test-Path -Path \$env:PSModuleAnalysisCachePath)) {  \
            Write-Host "'Waiting for $env:PSModuleAnalysisCachePath'" ; \
            Start-Sleep -Seconds 6 ; \
          }"

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
