FROM mcr.microsoft.com/powershell:latest

USER root

RUN apt-get update \
    && curl -fsSL https://get.docker.com | sh \
    && pwsh -NoLogo -NoProfile -c "install-module -Name Pester -Scope CurrentUser -force" 
