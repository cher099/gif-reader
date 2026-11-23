# Photos GIF

Photos GIF is a jailbreak tweak for iPhone 4S on iOS 6.1.3. It hooks image decoding inside the stock Photos app and supplies animated UIImage frames for GIF data, so a GIF can animate in the Photos viewer.

## Compatibility target

- iOS deployment target: 6.0 (intended for iOS 6.1.3)
- CPU: armv7
- Injection filter: stock Photos bundle, `com.apple.mobileslideshow`
- Uses UIKit, Foundation, ImageIO, and CoreGraphics APIs available on iOS 6.

## Build

The included GitHub Actions workflow builds the rootful armv7 Debian package on each push and can also be started manually. It assembles the split iOS 6.1 SDK, compiles the tweak, and uploads the `.deb` as an Actions artifact named `Photos-GIF-deb`.

For a local build with Theos and the iOS 6.1 SDK installed:

```sh
make package
```

## Install and use

Install `Photos-GIF-deb` with Cydia or Filza. Save an animated GIF to Camera Roll, fully close Photos, then reopen Photos and tap the GIF to view it. Thumbnail previews may remain static; animation is intended for the full-screen viewer.

The tweak is injected only into Photos. It does not add a separate app icon or import/download GIFs. Runtime behavior still needs testing on the target iPhone 4S running iOS 6.1.3.
