# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

ARG fromTag=bionic
ARG imageRepo=arm32v7/ubuntu

FROM ${imageRepo}:${fromTag} AS installer-env

ARG PS_VERSION=6.1.0
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-arm32.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}

RUN \
  apt-get update \
  && apt-get install --no-install-recommends ca-certificates libunwind8 libssl1.0 libicu60 wget --yes \
  && wget https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE} \
  && mkdir ~/powershell \
  && tar -xvf ./${PS_PACKAGE} -C ~/powershell \
  && ln -s /root/powershell/pwsh /usr/bin/pwsh \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
 
 ENTRYPOINT ["pwsh"]
