# DaVinci Resolve Video Converter for Nautilus File Manager

Converts video to a DaVinci Resolve–friendly MKV (AV1 + FLAC, with passthrough when already compatible). Also converts QuickTime MOV to MP4. Integrates with GNOME Nautilus via a Python context-menu extension.

## Dependencies

1. `bash`
2. `ffmpeg` (includes `ffprobe`)
3. `zenity`
4. `python3-nautilus` (Debian/Ubuntu) / `nautilus-python` (Fedora) / `python-nautilus` (Arch)

```bash
# Debian / Ubuntu
sudo apt install python3-nautilus

# Fedora
sudo dnf install nautilus-python

# Arch
sudo pacman -S python-nautilus
```

## Easy install / uninstall

From a clone of this repo:

```bash
chmod +x install.sh uninstall.sh install_uninstall-resolve.sh
./install.sh
```

To remove:

```bash
./uninstall.sh
```

Or double-click `resolveconverter-installer.desktop` and run it as a program (downloads and runs the remote installer). You can also run `ffmpeg-install_remote-resolve.sh` alone.

The installer:

- Installs `ffmpegconvert-resolve.sh` to `~/.local/bin` (or a path you choose)
- Installs a Nautilus Python extension for top-level context-menu items
- Restarts Nautilus with `nautilus -q` so the menu reloads

Re-run `./install.sh` to update; use `./uninstall.sh` to remove.

## Manual install

1. Copy `release/ffmpegconvert-resolve.sh` to `~/.local/bin/ffmpegconvert-resolve.sh` and `chmod +x` it.
2. Edit `SCRIPT_PATH` in `release/nautilus-python/ffmpegconvert_resolve.py`, copy it to `~/.local/share/nautilus-python/extensions/`, then run `nautilus -q`.

## Use

Right-click in Nautilus:

- **Convert for Resolve** — on video files or folders
- **Convert MOV to MP4** — on `.mov` / QuickTime files or folders

CLI:

```bash
~/.local/bin/ffmpegconvert-resolve.sh /path/to/file-or-dir [...]
~/.local/bin/ffmpegconvert-resolve.sh --to-mp4 /path/to/clip.mov
```

Resolve output is written next to the source as `originalname_ext_resolve.mkv` (example: `clip.mp4` → `clip_mp4_resolve.mkv`). MOV→MP4 writes `clip.mp4` next to `clip.mov`. If the target already exists, conversion is skipped (source files are never overwritten).

## Behavior notes

- **Resolve:** Video is passed through when already Resolve-friendly in Matroska (including AV1, ProRes, DNxHD/HR, CineForm, MJPEG, and similar). Otherwise it encodes to AV1 (VAAPI when available, else `libsvtav1`). Audio is passed through for FLAC / PCM / ALAC; otherwise converted to FLAC. Multi-stream audio is supported.
- **MOV→MP4:** Copies H.264/HEVC/etc. and AAC/MP3/AC3 when already MP4-safe; otherwise re-encodes to H.264 + AAC.
- Batch conversion works for multiple selections and for directories. Folder batching is best-effort.

## Related projects

General-purpose Dolphin converters: [dolphin-context-convert-davinci](https://github.com/MetalMan1245/dolphin-context-convert-davinci) (based on [dolphin-context-convert](https://github.com/NuVanDibe/dolphin-context-convert)).

## Versioning / GitHub Releases

The project version lives in [`VERSION`](VERSION) (semver, e.g. `1.0.0`).

Pushing a change to `VERSION` on `main` triggers a GitHub Action that creates a tagged Release (`v1.0.0`) with:

- `resolve-convert-nautilus-<version>.zip` — extract and run `./install.sh`
- `resolveconverter-installer-<version>.desktop` — optional one-click installer launcher

## Disclaimers

THIS IS VIBE CODED. Quality and robustness are not guaranteed. Fork or open issues as needed.
