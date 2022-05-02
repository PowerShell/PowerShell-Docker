# Copyright (c) Microsoft Corporation.
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
      unzip \
      git \
    && yum clean all \
    # remove cache folders and files
    && rm -rf /var/cache/yum

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-AmazonLinux

CMD [ "pwsh" ]
