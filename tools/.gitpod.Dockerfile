FROM mcr.microsoft.com/powershell:latest

USER root

RUN apt-get update \
    && apt-get --yes install docker \
    && pwsh -NoLogo -NoProfile -c "Install-module Pester -Scope CurrentUser -Force -MaximumVersion 4.99"
