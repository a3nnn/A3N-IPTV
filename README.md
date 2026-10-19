# A3N IPTV Player

A fast, lightweight IPTV player for Windows, built with Flutter and [media_kit](https://github.com/media-kit/media-kit) (libmpv).

> **A3N IPTV Player is a media player only.** It does not provide, host or distribute any channels, streams or playlists. You need your own Xtream Codes subscription.

## Features

- Xtream Codes login (username + password)
- Live TV with categories, search, favorites and pinned categories
- Preview player with program guide (EPG): now / next
- Full-screen mode with keyboard channel switching (▲ ▼), volume (◀ ▶) and mute (M)
- Movies and Series (seasons and episodes)
- Remembers the last channel and volume

## Download

Latest Windows installer:
**https://github.com/a3nnn/A3N-IPTV/releases/latest/download/A3N_IPTV_Player_Setup.exe**

## Build from source

Requirements: Flutter (stable), Visual Studio 2022 with *Desktop development with C++*.

```
flutter pub get
flutter build windows --release
```

The installer is built with [Inno Setup](https://jrsoftware.org/isinfo.php) from `installer.iss`. Official releases are built automatically by GitHub Actions (`.github/workflows/release.yml`) when a version tag (`v*`) is pushed.

## Code signing policy

Windows release binaries are built from this repository by GitHub Actions.
<!-- After SignPath approval, replace the line below with:
Free code signing provided by [SignPath.io](https://about.signpath.io), certificate by [SignPath Foundation](https://signpath.org).
-->
Code signing: application to SignPath Foundation pending.

**Team roles**
- Committer, reviewer and approver: [@a3nnn](https://github.com/a3nnn)

**Privacy policy**
This program will not transfer any information to other networked systems unless specifically requested by the user. It only connects to the IPTV server configured in `lib/config.dart`, to sign in with the credentials the user enters and to load channels, the program guide and streams. Credentials are stored locally on the user's computer only.

## License

[MIT](LICENSE)
