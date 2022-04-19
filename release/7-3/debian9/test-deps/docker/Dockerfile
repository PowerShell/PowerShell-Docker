# Docker image file that describes an Debian 9 image with PowerShell and test dependencies
ARG BaseImage=mcr.microsoft.com/powershell:debian-9

FROM ${BaseImage}

# Install dependencies and clean up
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        sudo \
        curl \
        wget \
        iputils-ping \
        iputils-tracepath \
        procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-Debian-9

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
