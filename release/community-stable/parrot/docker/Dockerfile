# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
# Docker image file that describes an Parrot image with PowerShell
# installed from Debian9 PowerShell package

# Define arg(s) needed for the From statement
ARG fromTag=latest
ARG imageRepo=parrotsec/core

FROM ${imageRepo}:${fromTag} AS installer-env

# Clear the entrypoint in parrotsec/parrot-core image
ENTRYPOINT [ ]

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
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Parrot-${fromTag}

# Installation
RUN \
    # update package list
    apt-get update \
    # install dependencies
    && apt-get install --no-install-recommends -y \
      # required for HttpClientHandler
      libcurl4 \
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
    # upgrade distro
    && apt-get dist-upgrade -y \
    # Download the Debian9 PowerShell Core package and save it
    && wget -O /tmp/powershell.deb --no-check-certificate ${PS_PACKAGE_URL} \
    # install powershell package
    && apt-get install --no-install-recommends -y /tmp/powershell.deb \
    # remove powershell package
    && rm -f /tmp/powershell.deb \
    # Give all user execute permissions and remove write permissions for others
    && chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
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
    # clean downloaded packages
    && apt-get clean \
    # remove package list
    && rm -rf /var/lib/apt/lists/*

# Define args needed only for the labels
ARG IMAGE_NAME=pshorg/powershellcommunity:parrot-latest
ARG VCS_REF="none"

# Add label last as it's just metadata and uses a lot of parameters
LABEL maintainer="PowerShell Team <powershellteam@hotmail.com>" \
      readme.md="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
      description="This Dockerfile will install the latest release of PowerShell." \
      org.label-schema.usage="https://github.com/PowerShell/PowerShell/tree/master/docker#run-the-docker-image-you-built" \
      org.label-schema.url="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
      org.label-schema.vcs-url="https://github.com/PowerShell/PowerShell-Docker" \
      org.label-schema.name="powershell" \
      org.label-schema.vendor="PowerShell" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.version=${PS_VERSION} \
      org.label-schema.schema-version="1.0" \
      org.label-schema.docker.cmd="docker run ${IMAGE_NAME} pwsh -c '$psversiontable'" \
      org.label-schema.docker.cmd.devel="docker run ${IMAGE_NAME}" \
      org.label-schema.docker.cmd.test="docker run ${IMAGE_NAME} pwsh -c Invoke-Pester" \
      org.label-schema.docker.cmd.help="docker run ${IMAGE_NAME} pwsh -c Get-Help"

CMD [ "pwsh" ]
