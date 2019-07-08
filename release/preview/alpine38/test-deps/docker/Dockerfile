# Docker image file that describes an Alpine image with PowerShell and test dependencies

ARG BaseImage=mcr.microsoft.com/powershell:alpine-3.8

FROM node:10.15.3-alpine as node

# Do nothing, just added to borrow the already built node files.

FROM ${BaseImage}

ENV NODE_VERSION 10.15.3
ENV YARN_VERSION=1.13.0
ENV NVM_DIR="/root/.nvm"

# workaround for Alpine to run in Azure DevOps
ENV NODE_NO_WARNINGS=1

# Copy node and yarn into image
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /opt/yarn-v${YARN_VERSION} /opt/yarn-v${YARN_VERSION}

RUN apk add --no-cache --virtual .pipeline-deps readline linux-pam \
    && apk add \
        bash \
        sudo \
        shadow \
        openssl \
        curl \
    && apk del .pipeline-deps \
    && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
    && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg

# Define args needed only for the labels
ARG VCS_REF="none"
ARG IMAGE_NAME=mcr.microsoft.com/powershell/test-deps:alpine-3.8
ARG PS_VERSION=6.2.0

LABEL maintainer="PowerShell Team <powershellteam@hotmail.com>" \
      readme.md="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
      description="This Dockerfile will install the latest release of PowerShell and tools needed for runing CI/CD container jobs." \
      org.label-schema.usage="https://github.com/PowerShell/PowerShell/tree/master/docker#run-the-docker-image-you-built" \
      org.label-schema.url="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
      org.label-schema.vcs-url="https://github.com/PowerShell/PowerShell-Docker" \
      org.label-schema.name="powershell" \
      org.label-schema.vendor="PowerShell" \
      org.label-schema.version=${PS_VERSION} \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.docker.cmd="docker run ${IMAGE_NAME} pwsh -c '$psversiontable'" \
      org.label-schema.docker.cmd.devel="docker run ${IMAGE_NAME}" \
      org.label-schema.docker.cmd.test="docker run ${IMAGE_NAME} pwsh -c Invoke-Pester" \
      org.label-schema.docker.cmd.help="docker run ${IMAGE_NAME} pwsh -c Get-Help" \
      com.azure.dev.pipelines.agent.handler.node.path="/usr/local/bin/node"

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
