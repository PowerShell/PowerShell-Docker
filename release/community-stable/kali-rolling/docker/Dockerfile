# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
# Docker image file that describes an Kali Rolling image with PowerShell
# installed from Debian9 PowerShell package

# Define arg(s) needed for the From statement
ARG fromTag=kali-rolling
ARG imageRepo=kalilinux/kali-linux-docker

FROM ${imageRepo}:${fromTag} AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=6.1.0
ARG PS_PACKAGE=powershell_${PS_VERSION}-1.debian.9_amd64.deb
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=6

# Download the Debian9 PowerShell Core package and save it
ADD ${PS_PACKAGE_URL} /tmp/powershell.deb

# Define Args for the needed to add the package
ARG KALI_REPO_KEY_PACKAGE_URL=https://http.kali.org/kali/pool/main/k/kali-archive-keyring/kali-archive-keyring_2018.1_all.deb

# Download the Kali repository package and save it
ADD ${KALI_REPO_KEY_PACKAGE_URL} /tmp/kali-archive-keyring_2018.1_all.deb

# Define Args for the needed to add the package
ARG DEBIAN_PACKAGE_URL=http://ftp.us.debian.org/debian/pool/main/i/icu/libicu57_57.1-6+deb9u2_amd64.deb

# Download the libicu57 Debian package and save it
ADD ${DEBIAN_PACKAGE_URL} /tmp/libicu57_57.1-6+deb9u2_amd64.deb

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
    DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0

# Installation
RUN \
    # install kali package to renew kali repository expired certificate in container image
    apt-get install /tmp/kali-archive-keyring_2018.1_all.deb \
    # remove kali package
    && rm -f /tmp/kali-archive-keyring_2018.1_all.deb \
    # install required libicu57 package
    && dpkg -i /tmp/libicu57_57.1-6+deb9u2_amd64.deb \
    # remove libicu57 package
    && rm -f /tmp/libicu57_57.1-6+deb9u2_amd64.deb \
    # update package list
    && apt-get update \
    # install dependencies
    && apt-get install -y \
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
    # enable en_US.UTF-8 locale
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    # generate locale
    && locale-gen && update-locale \
    # install powershell package
    && apt-get install -y /tmp/powershell.deb \
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

# Define args needed only for the labels
ARG IMAGE_NAME=pshorg/powershellcommunity:kali-kali-rolling
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
