# Docker image file that describes an CentOS7 image with PowerShell installed from Microsoft YUM Repo
ARG BaseImage=mcr.microsoft.com/powershell:ubi-8.4

FROM ${BaseImage}

# Install dependencies and clean up
RUN yum install -y \
        sudo \
        wget \
        openssl \
        hostname \
        iputils \
        procps-ng \
        git \
        unzip \
    && yum clean all \
    && rm -rf /var/cache/yum

ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-ubi-8.4

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
