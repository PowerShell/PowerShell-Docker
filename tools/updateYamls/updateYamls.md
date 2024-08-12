# Update Build Yamls

## Context

This `updateBuildYamls.ps1` script needs to be run before the build and release pipelines for PowerShell-Docker are kicked off. Running the script will produce channel-based yaml files, like &lt;channel&gt;ReleaseStage.yml for build and templatesReleasePipeline/&lt;channel&gt;ReleaseGetBuiltImages.yml for release, for each channel. Then a PR must be created with these newly added/updated yaml files as the build and release will rely on them.

## Running the Script

To update the &lt;channel&gt;releaseStage.yml and templatesReleasePipeline/&lt;channel&gt;ReleaseGetBuiltImages.yml files for all the channels, run:
 `./updateBuildYamls.ps1 -StableVersion <stableVersion> -PreviewVersion <previewVersion> -LtsVersion <ltsVersion>`.

If you want the channel versions from channels.json to be used, simply omit the -*Version parameters and run: `./updateBuildYamls.ps1`.

## Notes

The versions provided must match versioning syntax rules for stable and preview versions. Valid examples include 7.4.2 (stable) and v7.4.0-preview.5 (preview)
