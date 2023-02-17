# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Docker image file that describes an Ubuntu20.04 image with PowerShell installed from Microsoft APT Repo
ARG hostRegistry=psdockercache.azurecr.io
FROM ${hostRegistry}/ubuntu:20.04 AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=7.3.0-preview.8
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-x64.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=7-preview

# Download the Linux tar.gz and save it
ADD ${PS_PACKAGE_URL} /tmp/linux.tar.gz

RUN echo ${PS_PACKAGE_URL}

# define the folder we will be installing PowerShell to
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION

# Create the install folder
RUN mkdir -p ${PS_INSTALL_FOLDER}

# Unzip the Linux tar.gz
RUN tar zxf /tmp/linux.tar.gz -C ${PS_INSTALL_FOLDER}

# Start a new stage so we lose all the tar.gz layers from the final image
ARG hostRegistry=psdockercache.azurecr.io
FROM ${hostRegistry}/ubuntu:20.04 AS powershell

ARG PS_VERSION=7.3.0-preview.8
ARG PS_INSTALL_VERSION=7-preview

# Copy only the files we need from the previous stage
COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]

# Define Args and Env needed to create links
ARG PS_INSTALL_VERSION=7-preview
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Ubuntu-20.04

# Install dependencies and clean up
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    # less is required for help in powershell
        less \
    # requied to setup the locale
        locales \
    # required for SSL
        ca-certificates \
        gss-ntlmssp \
        libicu66 \
        libssl1.1 \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libstdc++6 \
        zlib1g \
    # PowerShell remoting over SSH dependencies
        openssh-client \
    # Download the Linux package and save it
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen $LANG && update-locale

# Give all user execute permissions and remove write permissions for others
RUN chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh-preview \
    # intialize powershell module cache
    # and disable telemetry
    && export POWERSHELL_TELEMETRY_OPTOUT=1 \
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
CMD [ "pwsh-preview" ]
