# Docker image file that describes an Ubuntu image with PowerShell and test dependencies
ARG BaseImage=mcr.microsoft.com/powershell:ubuntu-20.04

FROM ${BaseImage}

# Install dependencies and clean up
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        sudo \
        curl \
        wget \
        iputils-ping \
        iputils-tracepath \
        git \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-Ubuntu-20.04

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
