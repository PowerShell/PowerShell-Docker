# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

FROM mcr.microsoft.com/azurelinux/base/core:3.0 AS setup-tdnf-repa

    # Use the cache mount since this image does go into the final product
    RUN --mount=type=cache,target=/var/cache/tdnf \
        tdnf install -y azurelinux-repos \
        && tdnf makecache

# Download packages into a container so they don't take up space in the final stage
FROM setup-tdnf-repa AS installer-env

    # Define Args for the needed to add the package
    ARG PS_VERSION=7.5.0-preview.5
    ARG PACKAGE_VERSION=7.5.0_preview.5
    ARG PS_PACKAGE=powershell-preview-${PACKAGE_VERSION}-1.cm.x86_64.rpm
    ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
    ARG PS_INSTALL_VERSION=7-preview

    # Download the Linux tar.gz and save it
    ADD ${PS_PACKAGE_URL} /tmp/powershell.rpm

    # Don't use the cache mount since this image doesn't go into the final product and it causes issues with parralel operations with the next layer
    RUN tdnf install -y \
        wget \
        awk \
        tar \
        ca-certificates

    RUN --mount=type=cache,target=/var/cache/tdnf \
        --mount=type=cache,target=/installTmp \
        cd /installTmp \
        && wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
        && chmod +x ./dotnet-install.sh \
        && ./dotnet-install.sh -Channel 9.0 -Quality ga -Runtime dotnet -InstallDir /usr/share/dotnet

    RUN echo ${PS_PACKAGE_URL}

# Start a new stage so we lose all the package download layers from the final image
FROM setup-tdnf-repa AS powershell

    ARG PS_VERSION=7.5.0-preview.5

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
        POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-AzureLinux-3.0

    RUN --mount=type=cache,target=/var/cache/tdnf \
        # install dependencies
        tdnf install -y \
        # required for localization
        icu \
        # required for help in PowerShell
        less \
        # required for SSH
        openssh-clients \
        ca-certificates

    # Install dependencies and clean up
    RUN --mount=type=cache,target=/var/cache/tdnf \
        tdnf upgrade -y \
        # clean cached data
        && tdnf clean all

    COPY --from=installer-env /usr/share/dotnet /usr/share/dotnet

    RUN ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

    RUN --mount=type=cache,target=/var/cache/tdnf,rw \
        --mount=from=installer-env,target=/mnt/rpm,source=/tmp \
        rpm -i --nodeps /mnt/rpm/powershell.rpm

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
