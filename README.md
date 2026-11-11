# plymouth-themes

A collection of Plymouth themes (Linux boot splash screens).

| Theme | Description |
|---|---|
| `osx` | macOS-style Apple logo with progress bar (fan-made) |
| `connect` | "Connecting" dots animation (from adi1090x, see Credits) |
| `log` | Rotating gear + boot log (based on COGWHEEL-A-SPINNER-LOG-PGR-2-GRAY by DUKE93, GPLv3) |

## Previews

### osx

<img src="docs/previews/osx.png" alt="osx theme preview" width="600">

### connect

<img src="docs/previews/connect.gif" alt="connect theme preview" width="400">

### log

<img src="docs/previews/log-1.png" alt="log theme preview 1" width="400"> <img src="docs/previews/log-2.png" alt="log theme preview 2" width="400">

## Installation

One-liner (downloads the themes and installs them, no clone needed):

```bash
# interactive menu
curl -fsSL https://raw.githubusercontent.com/fhudint/plymouth-thems/main/install.sh | sudo bash

# install and activate a specific theme (osx, connect, log)
curl -fsSL https://raw.githubusercontent.com/fhudint/plymouth-thems/main/install.sh | sudo bash -s -- osx
```

> Piping a script into `sudo bash` runs it as root. Read [install.sh](install.sh) first if you want to know what it does.

Or clone the repo and use the install script:

```bash
sudo ./install.sh              # interactive menu
sudo ./install.sh osx          # install and activate a theme (osx, connect, log)
sudo ./install.sh --all        # install all themes without activating
sudo ./install.sh --remove osx # uninstall a theme
```

Manual way:

```bash
sudo cp -r osx /usr/share/plymouth/themes/      # or: connect, log
sudo plymouth-set-default-theme -R osx           # Fedora/Arch: -R rebuilds the initramfs
# Debian/Ubuntu: sudo update-alternatives --install ... then sudo update-initramfs -u
```

Plymouth also needs `splash` on the kernel command line (e.g. `quiet splash`).

## Try it without rebooting

```bash
sudo ./preview.sh osx 5   # show an installed theme for 5 seconds, then restore the previous one
```

## Credits

- The `connect` theme comes from [adi1090x/plymouth-themes](https://github.com/adi1090x/plymouth-themes) by Aditya Shakya ([@adi1090x](https://github.com/adi1090x)). This repo is not a fork; only the `connect` pack was taken from the 80+ packs in that repository. The original license is in [connect/LICENSE](connect/LICENSE).
- The `log` theme is based on COGWHEEL-A-SPINNER-LOG-PGR-2-GRAY by DUKE93.

## Disclaimer

The `osx` theme is a fan-made tribute and is not affiliated with, endorsed by, or sponsored by Apple Inc. Apple and the Apple logo are trademarks of Apple Inc., used here for illustrative purposes only. Remove the theme if you do not have the right to use these marks in your context.

## License

The `log` theme is derived from DUKE93's work and is licensed under GNU GPL v3 or later. The `connect` theme keeps its original license, included in its folder.
