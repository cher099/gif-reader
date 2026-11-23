# Photos GIF

Photos GIF is a jailbreak tweak for iPhone 4S running iOS 6.1.3. It adds animated GIF playback to the stock Photos app's full-screen viewer.

## How it works

GIF frames are decoded on demand at their original size. The tweak keeps the current frame in memory and replaces it as playback advances, instead of keeping every decoded frame at once.

## Compatibility

- iOS 6.0 or later; built for iOS 6.1.3
- ARMv7, including iPhone 4S
- Injects into the stock Photos app (`com.apple.mobileslideshow`)
- Uses UIKit and ImageIO APIs available on iOS 6, plus the Photos framework hook used by that version

## Known limitation

Swiping backward to a GIF in the full-screen viewer may freeze Photos. To view that GIF, return to Camera Roll and open it again. Opening a GIF directly in iFile is not supported.

## Install

Download the `Photos-GIF-deb` artifact from the repository's GitHub Actions build, extract the ZIP, and install the `.deb` with Cydia or Filza. The package updates the existing `com.cher099.photosgif` installation.

The build workflow names the package `Photos-GIF_<version>_iphoneos-arm.deb`.

## Build

GitHub Actions builds a rootful ARMv7 Debian package for iOS 6.1. It assembles the split SDK, compiles the tweak, and uploads the package as an artifact.

For a local build with Theos and the iOS 6.1 SDK installed:

```sh
make package
```

## License

This project is licensed under the GNU General Public License version 3. See [LICENSE](LICENSE) for the full terms.
