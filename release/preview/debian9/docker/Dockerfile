# Docker image file that describes an Debian 9 image with PowerShell installed from Microsoft APT Repo
ARG fromTag=stretch-slim
ARG imageRepo=debian

FROM ${imageRepo}:${fromTag} AS installer-env

ARG PS_VERSION=7.0.0-preview.1
ARG PS_PACKAGE=powershell-preview_${PS_VERSION}-1.debian.9_amd64.deb
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}

# Define ENVs for Localization/Globalization
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Debian-9

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
    # enable en_US.UTF-8 locale
    && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    # generate locale
    && locale-gen && update-locale \
    # remove powershell package
    && rm /tmp/powershell.deb \
    && ln -sf /opt/microsoft/powershell/7-preview/pwsh /usr/bin/pwsh \
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
