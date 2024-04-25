# Update Build Yamls

## Context

This `updateBuildYamls.ps1` script needs to be run before the build pipeline for PowerShell-Docker is kicked off. Running the script will produce a channel based yaml file, like &lt;channel&gt;ReleaseStage.yml for each channel. Then a PR must be created with these newly added/updated yaml files as the build will rely on them.

## Running the Script

To update the releaseStage.yml file for all the channels, run `./updateBuildYamls.ps1 -StableVersion <stableVersion> -PreviewVersion <previewVersion> -LtsVersion <ltsVersion>`.

If you want the channel versions from channels.json to be used, simply omit the -*Version parameters and run, `./updateBuildYamls.ps1`.

## Notes

The versions provided must match versioning syntax rules for stable and preview versions. Valid examples include 7.4.2 (stable) and v7.4.0-preview.5 (preview)
