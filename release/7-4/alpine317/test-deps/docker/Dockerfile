# Docker image file that describes an Alpine image with PowerShell and test dependencies

ARG BaseImage=mcr.microsoft.com/powershell:alpine-3.17

FROM ${BaseImage}

ENV NODE_VERSION=14.17.6 \
    YARN_VERSION=1.22.5 \
    NVM_DIR="/root/.nvm" \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-TestDeps-Alpine-3.17

# workaround for Alpine to run in Azure DevOps
ENV NODE_NO_WARNINGS=1

RUN apk add --no-cache --virtual .pipeline-deps readline linux-pam \
    && apk add --no-cache \
        bash \
        sudo \
        shadow \
        openssl \
        curl \
        git \
        unzip \
        musl \
        musl-locales \
        nodejs \
    && apk update \
    && apk upgrade \
    && apk del .pipeline-deps \
    && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
    && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg

LABEL com.azure.dev.pipelines.agent.handler.node.path="/usr/local/bin/node"

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh" ]
