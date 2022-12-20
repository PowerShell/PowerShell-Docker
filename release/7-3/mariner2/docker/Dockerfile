# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

FROM mcr.microsoft.com/cbl-mariner/base/core:2.0 AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=7.3.0-preview.8
ARG PACKAGE_VERSION=7.3.0_preview.8
ARG PS_PACKAGE=powershell-preview-${PACKAGE_VERSION}-1.cm.x86_64.rpm
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=7-preview

# Download the Linux tar.gz and save it
ADD ${PS_PACKAGE_URL} /tmp/powershell.rpm

RUN echo ${PS_PACKAGE_URL}

# Start a new stage so we lose all the tar.gz layers from the final image
FROM mcr.microsoft.com/cbl-mariner/base/core:2.0 AS powershell

ARG PS_VERSION=7.3.0-preview.8
ARG PS_INSTALL_VERSION=7-preview

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
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Mariner-2.0

# Install dependencies and clean up
RUN --mount=type=cache,target=/var/cache/tdnf \
    tdnf install -y mariner-repos-microsoft-preview \
    && tdnf makecache \
    # install dependencies
    && tdnf install -y \
    # required for localization
    icu \
    # required for help in PowerShell
    less \
    # required for SSH
    openssh-clients \
    ca-certificates \
    dotnet-runtime-7.0 \
    # upgrade packages
    && tdnf upgrade -y \
    # clean cached data
    && tdnf clean all

RUN --mount=type=cache,target=/var/cache/tdnf,rw \
    --mount=from=installer-env,target=/mnt/rpm,source=/tmp \
    rpm -i /mnt/rpm/powershell.rpm

# Create the pwsh symbolic link that points to powershell
RUN if [ -f "/opt/microsoft/powershell/7-preview/pwsh" ]; then ln -sf /opt/microsoft/powershell/7-preview/pwsh /usr/bin/pwsh; fi

# intialize powershell module cache
# and disable telemetry for this ONE session
RUN export POWERSHELL_TELEMETRY_OPTOUT=1 \
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
