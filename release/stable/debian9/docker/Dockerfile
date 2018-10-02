# Docker image file that describes an Debian 9 image with PowerShell installed from Microsoft APT Repo
ARG fromTag=stretch

FROM debian:${fromTag}

ARG PS_VERSION=6.1.0
ARG PS_VERSION_POSTFIX=-1.debian.9
ARG IMAGE_NAME=mcr.microsoft.com/powershell:debian-jessie
ARG VCS_REF="none"

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-utils \
        ca-certificates \
        curl \
        apt-transport-https \
        locales \
        gnupg \
        less

# Setup the locale
ENV LANG en_US.UTF-8
ENV LC_ALL $LANG
RUN locale-gen $LANG && update-locale

# Import the public repository GPG keys
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

# Register the Microsoft Product feed
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" > /etc/apt/sources.list.d/microsoft.list

# Install powershell from Microsoft Repo
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
	powershell=${PS_VERSION}${PS_VERSION_POSTFIX} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
