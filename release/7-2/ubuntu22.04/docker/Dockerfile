# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Download the deb file in this image
FROM ubuntu:22.04 AS installer-env

COPY ${PS_INSTALL_PATH} /tmp/powershell.deb

# Define ENVs for Localization/Globalization
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Ubuntu-22.04

# Install dependencies and clean up
RUN --mount=from=installer-env,target=/mnt/pwsh,source=/tmp \
    --mount=type=cache,target=/var/lib/apt \
    --mount=type=cache,target=/var/cache/apt \
    apt-get update \
    && apt-get install --no-install-recommends -y /mnt/pwsh/powershell.deb \
    && apt-get install --no-install-recommends -y \
    # less is required for help in powershell
        less \
    # required to setup the locale
        locales \
    # required for SSL
        ca-certificates \
        gss-ntlmssp \
        liblttng-ust1 \
    # PowerShell remoting over SSH dependencies
        openssh-client \
    && apt-get dist-upgrade -y \
    && locale-gen $LANG && update-locale \
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
CMD [ "pwsh" ]
