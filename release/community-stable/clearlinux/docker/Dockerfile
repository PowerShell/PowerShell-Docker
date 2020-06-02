# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
# Docker image file that describes an Intel Clear Linux image with PowerShell
# installed from full PowerShell linux tar.gz package

FROM clearlinux:latest AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=7.0.1
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-x64.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=7

# Download the PowerShell Core Linux tar.gz and save it
ADD ${PS_PACKAGE_URL} /tmp/powershell-linux.tar.gz

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
    DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0 \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-ClearLinux-${fromTag}

# Installation
RUN \
    # install dependencies
    swupd bundle-add \
      less \
    # create powershell folder
    && mkdir -p ${PS_INSTALL_FOLDER} \
    # uncompress powershell linux tar file
    && tar zxf /tmp/powershell-linux.tar.gz -C ${PS_INSTALL_FOLDER} \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
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
    && swupd update \
    # clean downloaded packages
    && swupd clean --all

CMD [ "pwsh" ]
