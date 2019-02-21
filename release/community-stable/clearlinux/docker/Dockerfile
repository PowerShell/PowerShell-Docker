# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
# Docker image file that describes an Intel Clear Linux image with PowerShell
# installed from full PowerShell linux tar.gz package

# Define arg(s) needed for the From statement
ARG fromTag=base
ARG imageRepo=clearlinux

FROM ${imageRepo}:${fromTag} AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=6.1.0
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-x64.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=6

# Download the PowerShell Core Linux tar.gz and save it
ADD ${PS_PACKAGE_URL} /tmp/powershell-linux.tar.gz

# Define Args for the needed to add the package
ARG GNU_LINUX_LESS_PACKAGE_URL=https://ftp.gnu.org/gnu/less/less-530.tar.gz

# Download the less tar.gz and save it
ADD ${GNU_LINUX_LESS_PACKAGE_URL} /tmp/less.tar.gz

# Define Args and Env needed to create links
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

# Installation
RUN \
    # install dependencies
    swupd bundle-add \
      # required libstdc++.so.6
      # required bundle to make less executable
      os-core-dev \
      # required libcrypto.so.1.0.0
      # required libssl.so.1.0.0
      # required these files to be copied to second stage
      cryptoprocessor-management \
    # create less folder
    && mkdir -p /tmp/less \
    # uncompress GNU/Linux less tar file
    && tar zxf /tmp/less.tar.gz -C /tmp/less --strip-components 1 \
    # make less executable
    && ./tmp/less/configure \
    # create powershell folder
    && mkdir -p ${PS_INSTALL_FOLDER} \
    # uncompress powershell linux tar file
    && tar zxf /tmp/powershell-linux.tar.gz -C ${PS_INSTALL_FOLDER}

# Start a new stage so we lose all the tar.gz layers from the final image
FROM ${imageRepo}:${fromTag}

# Copy only the files we need from the previous stage
COPY --from=installer-env ["/usr/bin/less", "/usr/bin/less"]
COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]

# Define Args and Env needed to create links
ARG PS_VERSION=6.1.0
ARG PS_INSTALL_VERSION=6
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # Set up PowerShell module analysis cache path
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    # Opt out of SocketsHttpHandler in DotNet Core 2.1 to use HttpClientHandler
    DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0

RUN \
    # install dependencies
    swupd bundle-add \
      # required package for International Components for Unicode
      runtime-libs-boost \
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

# Copy only the files we need from the previous stage after distro upgrade
# These files are required to resolve SSL issue with Invoke-WebRequest
COPY --from=installer-env ["/usr/lib64/libcrypto.so.1.0.0", "/usr/lib64/libcrypto.so.1.0.0"]
COPY --from=installer-env ["/usr/lib64/libssl.so.1.0.0", "/usr/lib64/libssl.so.1.0.0"]

# Define args needed only for the labels
ARG IMAGE_NAME=pshorg/powershellcommunity:clearlinux-base
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
