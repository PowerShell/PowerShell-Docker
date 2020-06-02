# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
# Docker image file that describes an Amazon Linux image with PowerShell
# installed from RHEL7 PowerShell package

# Define arg(s) needed for the From statement
ARG BaseImage=pshorg/powershellcommunity:amazonlinux-2.0

FROM ${BaseImage}

ARG fromTag=2.0.20181010

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

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-AmazonLinux-${fromTag}

CMD [ "pwsh" ]
