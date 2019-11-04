FROM mcr.microsoft.com/powershell:latest

USER root

RUN apt-get update \
    && apt-get install --yes software-properties-common curl \
    && curl -fsSL https://get.docker.com -o get-docker.sh | sh \
    && curl -fsSL https://get.docker.com/rootless | sh \
    && pwsh -NoLogo -NoProfile -c "Install-Module -Name Pester -Scope CurrentUser -Force"
