# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
# Docker image file that describes an Kali Rolling image with PowerShell
# installed from Debian11 PowerShell package

FROM kalilinux/kali-rolling:latest AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=7.0.1
ARG PS_PACKAGE=powershell_${PS_VERSION}-1.debian.11_amd64.deb
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=7

# Define Args and Env needed to create links
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # Set up PowerShell module analysis cache path
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    # Opt out of SocketsHttpHandler in DotNet Core 2.1 to use HttpClientHandler
    # with installed libcurl4 package to resolve
    # Invoke-WebRequest : Authentication failed" issue when executing using
    # docker run [OPTIONS] IMAGE[:TAG|@DIGEST] [Invoke-WebRequest] [-Uri <HTTPS URL>]
    DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0 \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-KaliLinux-${fromTag}

# Installation
RUN \
    # update package list
    apt-get update \
    # install dependencies
    && apt-get install --no-install-recommends -y \
      # required for HttpClientHandler
      libcurl4 \
      # required for SSL
      ca-certificates \
      # required for help in powershell
      less \
      # required to setup the locale
      locales \
      # required to support NTLM for PSRemoting
      gss-ntlmssp \
      wget \
      libicu63 \
    # enable en_US.UTF-8 locale
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    # generate locale
    && locale-gen && update-locale \
    # download the powershell package
    && wget -O /tmp/powershell.deb --no-check-certificate ${PS_PACKAGE_URL} \
    # install powershell package
    && apt-get install --no-install-recommends -y /tmp/powershell.deb \
    # remove powershell package
    && rm -f /tmp/powershell.deb \
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
          }" \
    # upgrade distro
    && apt-get dist-upgrade -y \
    # clean downloaded packages
    && apt-get clean \
    # remove package list
    && rm -rf /var/lib/apt/lists/*

CMD [ "pwsh" ]
