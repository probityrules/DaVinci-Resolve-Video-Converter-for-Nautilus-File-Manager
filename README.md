# DaVinci Resolve Video Converter for Nautilus File Manager

Converts video to a DaVinci Resolve–friendly MKV (AV1 + FLAC, with passthrough when already compatible). Integrates with GNOME Nautilus via a Python context-menu extension when available, or a Nautilus Scripts fallback.

## Dependencies

**Required**

1. `bash`
2. `ffmpeg` (includes `ffprobe`)
3. `zenity`

**Recommended (top-level right-click menu)**

4. `python3-nautilus` (Debian/Ubuntu) / `nautilus-python` (Fedora) / `python-nautilus` (Arch)

Without the Python package, the installer installs a **Scripts** submenu entry instead.

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
- Prefers a Nautilus Python extension for a top-level **Convert for Resolve** menu item
- Falls back to `~/.local/share/nautilus/scripts/Convert for Resolve` if `python3-nautilus` is missing
- Restarts Nautilus with `nautilus -q` so the menu reloads

Re-run `./install.sh` to update; use `./uninstall.sh` to remove.

### Package hints for the Python extension

```bash
# Debian / Ubuntu
sudo apt install python3-nautilus

# Fedora
sudo dnf install nautilus-python

# Arch
sudo pacman -S python-nautilus
```

Then re-run `./install.sh` and choose the extension option.

## Manual install

1. Copy `release/ffmpegconvert-resolve.sh` to `~/.local/bin/ffmpegconvert-resolve.sh` and `chmod +x` it.
2. **Extension (preferred):** edit `SCRIPT_PATH` in `release/nautilus-python/ffmpegconvert_resolve.py`, copy it to `~/.local/share/nautilus-python/extensions/`, then run `nautilus -q`.
3. **Scripts fallback:** edit `SCRIPT_PATH` in `release/nautilus-scripts/Convert for Resolve`, copy it to `~/.local/share/nautilus/scripts/`, `chmod +x`, then run `nautilus -q`.

## Use

- **With extension:** right-click video(s) or folder(s) in Nautilus → **Convert for Resolve**
- **With Scripts fallback:** right-click → **Scripts** → **Convert for Resolve**
- **CLI:** `~/.local/bin/ffmpegconvert-resolve.sh /path/to/file-or-dir [...]`

Output is written next to the source as `originalname_ext_resolve.mkv` (example: `clip.mp4` → `clip_mp4_resolve.mkv`). If that file already exists, conversion is skipped (source files are never overwritten).

## Behavior notes

- Video is passed through when already Resolve-friendly in Matroska (including AV1, ProRes, DNxHD/HR, CineForm, MJPEG, and similar). Otherwise it encodes to AV1 (VAAPI when available, else `libsvtav1`).
- Audio is passed through for FLAC / PCM / ALAC; otherwise converted to FLAC. Multi-stream audio is supported.
- Batch conversion works for multiple selections and for directories (common video extensions). Folder batching is best-effort.

## Related projects

General-purpose Dolphin converters: [dolphin-context-convert-davinci](https://github.com/MetalMan1245/dolphin-context-convert-davinci) (based on [dolphin-context-convert](https://github.com/NuVanDibe/dolphin-context-convert)).

## Versioning / GitHub Releases

The project version lives in [`VERSION`](VERSION) (semver, e.g. `1.0.0`).

Pushing a change to `VERSION` on `main` triggers a GitHub Action that creates a tagged Release (`v1.0.0`) with:

- `resolve-convert-nautilus-<version>.zip` — extract and run `./install.sh`
- `resolveconverter-installer-<version>.desktop` — optional one-click installer launcher

## Disclaimers

THIS IS VIBE CODED. Quality and robustness are not guaranteed. Fork or open issues as needed.
