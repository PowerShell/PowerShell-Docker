# Docker image file that describes an Ubuntu image with PowerShell and test dependencies
ARG BaseImage=mcr.microsoft.com/powershell:ubuntu-16.04

FROM ${BaseImage}

# Install dependencies and clean up
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        sudo \
        curl \
        wget \
        iputils-ping \
        iputils-tracepath \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-Ubuntu-16.04

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
