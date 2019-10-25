# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

ARG fromTag=bionic
ARG imageRepo=arm32v7/ubuntu

FROM ${imageRepo}:${fromTag} AS installer-env

ARG PS_VERSION=6.2.3
ENV PS_PACKAGE=powershell-${PS_VERSION}-linux-arm32.tar.gz
ENV PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=7-preview

# define the folder we will be installing PowerShell to
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION

# Create the install folder
RUN mkdir -p ${PS_INSTALL_FOLDER}

ARG PS_PACKAGE_URL_BASE64

RUN apt-get update \
    && apt-get install --no-install-recommends ca-certificates wget --yes

RUN echo 'in task' \
    && if [ -n "${PS_PACKAGE_URL_BASE64}" ]; then \
        echo 'using base64' \
        && export url=$(echo "${PS_PACKAGE_URL_BASE64}" | base64 --decode --input -);\
    else \
        echo 'using unencoded' \
        && export url="${PS_PACKAGE_URL}"; \
    fi \
    && echo "url: $url" \
    && wget "$url" \
    && echo 'task done'


RUN ls -l ${PS_PACKAGE}
    # Unzip the Linux tar.gz
RUN tar zxf "./${PS_PACKAGE}" -C ${PS_INSTALL_FOLDER}

FROM ${imageRepo}:${fromTag} AS final-image

# Define Args and Env needed to create links
ARG PS_INSTALL_VERSION=7-preview
ARG PS_VERSION=6.2.3

ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-arm32v7-Ubuntu-18.04

# Copy only the files we need from the previous stage
COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]


RUN \
  apt-get update \
  && apt-get install --no-install-recommends ca-certificates libunwind8 libssl1.0 libicu60 less --yes

    # Give all user execute permissions and remove write permissions for others
RUN chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    # Create the pwsh-preview symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh-preview

# Define args needed only for the labels
ARG VCS_REF="none"
ARG IMAGE_NAME=mcr.microsoft.com/powershell:preview-arm32v7-ubuntu-bionic

LABEL maintainer="PowerShell Team <powershellteam@hotmail.com>" \
      readme.md="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
      description="This Dockerfile will install the latest release of PowerShell." \
      org.label-schema.usage="https://github.com/PowerShell/PowerShell/tree/master/docker#run-the-docker-image-you-built" \
      org.label-schema.url="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
      org.label-schema.vcs-url="https://github.com/PowerShell/PowerShell-Docker" \
      org.label-schema.name="powershell" \
      org.label-schema.vendor="PowerShell" \
      org.label-schema.version=${PS_VERSION} \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.docker.cmd="docker run ${IMAGE_NAME} pwsh -c '$psversiontable'" \
      org.label-schema.docker.cmd.devel="docker run ${IMAGE_NAME}" \
      org.label-schema.docker.cmd.test="docker run ${IMAGE_NAME} pwsh -c Invoke-Pester" \
      org.label-schema.docker.cmd.help="docker run ${IMAGE_NAME} pwsh -c Get-Help"

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
