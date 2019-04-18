# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
# Docker image file that describes an Amazon Linux image with PowerShell
# installed from RHEL7 PowerShell package

# Define arg(s) needed for the From statement
ARG BaseImage=pshorg/powershellcommunity:amazonlinux-2.0

FROM ${BaseImage}

# Installation
RUN \
    # install dependencies
    yum install -y \
      # adds adduser
      shadow-utils \
      sudo \
      # add su
      util-linux \
      iputils \
      hostname \
      procps \
      wget \
      openssl \
      tar \
    && yum clean all \
    # remove cache folders and files
    && rm -rf /var/cache/yum

# Define args needed only for the labels
ARG IMAGE_NAME=pshorg/powershellcommunity/test-deps:amazonlinux-2.0.20181114
ARG VCS_REF="none"
ARG PS_VERSION=6.1.0

# Add label last as it's just metadata and uses a lot of parameters
LABEL maintainer="PowerShell Team <powershellteam@hotmail.com>" \
      readme.md="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
      description="This Dockerfile will install the latest release of PowerShell and tools needed for runing CI/CD container jobs." \
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
