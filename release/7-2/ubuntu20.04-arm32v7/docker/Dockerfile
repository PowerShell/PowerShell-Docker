# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

FROM --platform=linux/arm/v7 ubuntu:focal AS installer-env

    ARG PS_VERSION=7.2.3
    ENV PS_PACKAGE=powershell-${PS_VERSION}-linux-arm32.tar.gz
    ENV PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
    ARG PS_INSTALL_VERSION=7

    # define the folder we will be installing PowerShell to
    ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION
    # Create the install folder
    RUN mkdir -p ${PS_INSTALL_FOLDER}
    ARG PS_PACKAGE_URL_BASE64
    RUN --mount=type=cache,target=/var/lib/apt \
        --mount=type=cache,target=/var/cache/apt \
        apt-get update \
        && apt-get install --no-install-recommends ca-certificates wget --yes
    RUN update-ca-certificates -f
    RUN echo 'in task' \
        && if [ -n "${PS_PACKAGE_URL_BASE64}" ]; then \
            echo 'using base64' \
            && export url=$(echo "${PS_PACKAGE_URL_BASE64}" | base64 --decode -);\
        else \
            echo 'using unencoded' \
            && export url="${PS_PACKAGE_URL}"; \
        fi \
        && echo "url: $url" \
        && wget -O /tmp/powershell.tar.gz "$url" \
        && echo 'task done'
    RUN ls -l /tmp/powershell.tar.gz
        # Unzip the Linux tar.gz
    RUN tar zxf /tmp/powershell.tar.gz -C ${PS_INSTALL_FOLDER}

FROM --platform=linux/arm/v7 ubuntu:focal AS final-image

    # Define Args and Env needed to create links
    ARG PS_INSTALL_VERSION=7
    ARG PS_VERSION=7.2.3

    ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
        \
        # Define ENVs for Localization/Globalization
        DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
        LC_ALL=en_US.UTF-8 \
        LANG=en_US.UTF-8 \
        # set a fixed location for the Module analysis cache
        PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
        POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-arm32v7-Ubuntu-20.04
    # Copy only the files we need from the previous stage
    COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]
    RUN --mount=type=cache,target=/var/lib/apt \
        --mount=type=cache,target=/var/cache/apt \
        apt-get update \
        && apt-get install --no-install-recommends ca-certificates libssl1.1 libicu66 less --yes

        # Give all user execute permissions and remove write permissions for others
    RUN chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
        # Create the pwsh symbolic link that points to powershell
        && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh

    # Use PowerShell as the default shell
    # Use array to avoid Docker prepending /bin/sh -c
    CMD [ "pwsh" ]
