# Photos GIF

Photos GIF is a jailbreak tweak for iPhone 4S on iOS 6.1.3 that adds animated GIF playback to the stock Photos app's full-screen viewer.

GIF frames are decoded on demand at their original size. Photos GIF keeps only the current frame decoded and replaces it as playback advances, so it does not need to hold a full animation's decoded frames in memory.

## Compatibility target

- iOS deployment target: 6.0 (intended for iOS 6.1.3)
- CPU: armv7
- Injection filter: stock Photos app (`com.apple.mobileslideshow`)
- Uses UIKit, Foundation, and ImageIO APIs available on iOS 6, plus the private PhotoLibrary tile hook from that OS generation.

## Build

GitHub Actions builds the rootful armv7 Debian package on each push and can also be started manually. It assembles the split iOS 6.1 SDK, compiles the tweak, and uploads the `.deb` as an Actions artifact.

For a local build with Theos and the iOS 6.1 SDK installed:

```sh
make package
```

## Install and use

Install the `.deb` with Cydia or Filza, then open a GIF in the Photos app and view it full-screen. Thumbnail previews may remain static. Opening a GIF directly in iFile is outside this tweak's scope.

The tweak does not add a separate app icon or import/download GIFs. Runtime behavior still needs testing on the target iPhone 4S running iOS 6.1.3.

