FROM mcr.microsoft.com/powershell:latest

USER root

RUN pwsh -NoLogo -NoProfile -c "Install-module Pester -Scope CurrentUser -Force -MaximumVersion 4.99"
