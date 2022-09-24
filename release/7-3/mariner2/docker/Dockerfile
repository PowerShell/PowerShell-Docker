# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

FROM mcr.microsoft.com/cbl-mariner/base/core:2.0 AS powershell

ARG PS_VERSION=7.3.0-preview.4

# Define Args and Envs
ENV PS_INSTALL_VERSION=7-preview \
    PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
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
    && tdnf update -y \
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
    && tdnf clean all \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh-preview \
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
