# GIF Everywhere

GIF Everywhere is a jailbreak tweak for iPhone 4S on iOS 6.1.3. It injects into UIKit apps and replaces GIFs loaded through UIImage data/file APIs with animated UIImage frames. A Photos-specific full-size tile hook handles the stock Photos viewer too.

## Compatibility target

- iOS deployment target: 6.0 (intended for iOS 6.1.3)
- CPU: armv7
- Injection filter: UIKit framework, `com.apple.UIKit`, for systemwide app coverage without targeting background daemons
- Uses UIKit, Foundation, and ImageIO APIs available on iOS 6, plus the private PhotoLibrary tile hook from that OS generation.

## Build

The included GitHub Actions workflow builds the rootful armv7 Debian package on each push and can also be started manually. It assembles the split iOS 6.1 SDK, compiles the tweak, and uploads the `.deb` as an Actions artifact named `GIF-Everywhere-deb`.

For a local build with Theos and the iOS 6.1 SDK installed:

```sh
make package
```

## Install and use

Install `GIF-Everywhere-deb` with Cydia or Filza. Apps that load GIFs through UIKit's UIImage data/file APIs should display animation automatically. In Photos, tap a GIF to view it full-screen; thumbnail previews may remain static.

The tweak does not add a separate app icon or import/download GIFs. Apps using their own GIF decoder may not be covered. Runtime behavior still needs testing on the target iPhone 4S running iOS 6.1.3.
