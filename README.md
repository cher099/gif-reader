# Giffy

Giffy is a small UIKit application for jailbroken iPhone 4S devices. It browses folders under `/var/mobile/Media`, lists GIF files, and plays their frames with ImageIO and `UIImageView` animation.

## Compatibility target

- iOS deployment target: 6.0 (intended to run on iOS 6.1.3)
- CPU: armv7 (iPhone 4S)
- APIs: UIKit, Foundation, ImageIO, and CoreGraphics, all available before iOS 6. No Swift, extensions, modern photo-picker APIs, or newer image animation APIs are used.

## Build on macOS

The included GitHub Actions workflow builds on each push and can also be started manually from the Actions tab. It installs Theos, reassembles the split iOS 6.1 SDK, builds the rootful armv7 package, and saves the `.deb` as an Actions artifact named `Giffy-deb`.

For a local build, install Theos and an iOS 6.1-capable SDK/toolchain on macOS, then from this directory run:

```sh
make package
```

Rootful is Theos' default package layout, which matches classic iOS 6 jailbreaks. The generated `.deb` is normally placed under `packages/`.

## Install

Copy GIF files into `/var/mobile/Media` or a subfolder using a file manager. Install the generated package with Cydia or Filza, then launch Giffy from SpringBoard. Filza can also open the `.deb` directly.

## Build status

A successful GitHub Actions run confirms that the source compiles and the `.deb` packages correctly. This project has not yet been built on this workspace. The app browses `/var/mobile/Media`; it does not integrate with the Photos app or download GIFs.
