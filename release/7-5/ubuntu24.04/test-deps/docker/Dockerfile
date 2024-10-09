# Docker image file that describes an Ubuntu image with PowerShell and test dependencies
ARG BaseImage=mcr.microsoft.com/powershell:ubuntu-24.04

FROM ${BaseImage}

# Install dependencies and clean up
RUN --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update \
    && apt-get install --no-install-recommends -y \
        sudo \
        curl \
        wget \
        iputils-ping \
        iputils-tracepath \
        git \
        unzip \
    && apt-get clean

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-Ubuntu-24.04

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
