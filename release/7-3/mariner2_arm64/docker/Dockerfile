# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

FROM --platform=linux/arm64 mcr.microsoft.com/cbl-mariner/base/core:2.0 AS installer-env

    # Define Args for the needed to add the package
    ARG PS_VERSION=7.3.1
    ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-arm64.tar.gz
    ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
    ARG PS_INSTALL_VERSION=7

    # Define the folder we will be installing PowerShell to.
    ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/${PS_INSTALL_VERSION}

    # Create the install folder.
    RUN mkdir -p ${PS_INSTALL_FOLDER}

    ARG PS_PACKAGE_URL_BASE64

    RUN --mount=type=cache,target=/var/cache/tdnf \
        tdnf update -y \
        && tdnf install -y ca-certificates wget tar

    RUN echo 'in task' \
        && if [ -n "${PS_PACKAGE_URL_BASE64}" ];  then \
            echo 'using base64' \
            && export url=$(echo "${PS_PACKAGE_URL_BASE64}" | base64 --decode -); \
        else \
            echo 'using unencoded' \
            && export url="${PS_PACKAGE_URL}"; \
        fi \
        && echo "url: $url" \
        && wget -O /tmp/powershell.tar.gz "$url" \
        && echo 'task done'

    RUN ls -l /tmp/powershell.tar.gz

    # Unzip the linux powershell.tar.gz
    RUN tar zxf /tmp/powershell.tar.gz -C ${PS_INSTALL_FOLDER}

FROM --platform=linux/arm64 mcr.microsoft.com/cbl-mariner/base/core:2.0 AS final-image

    # Define Args and Env needed to create links
    ARG PS_INSTALL_VERSION=7
    ARG PS_VERSION=7.3.1

    ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
        \
        # Define ENVs for Localization/Globalization
        DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
        LC_ALL=en_US.UTF-8 \
        LANG=en_US.UTF-8 \
        # set a fixed location for the Module analysis cache
        PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
        POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-arm64v7-Mariner-2

    # Copy only the files we need from the previous stage
    COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]

    RUN --mount=type=cache,target=/var/cache/tdnf,rw \
        tdnf update -y \
        && tdnf install -y icu less openssh-clients ca-certificates dotnet-runtime-7.0 \
        && tdnf upgrade -y \
        && tdnf clean all

        # Give all user execute permissions and remove write permissions for others
    RUN chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
        # Create the pwsh symbolic link that points to powershell
        && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh

    # Use PowerShell as the default shell
    # Use array to avoid Docker prepending /bin/sh -c
    CMD [ "pwsh" ]
