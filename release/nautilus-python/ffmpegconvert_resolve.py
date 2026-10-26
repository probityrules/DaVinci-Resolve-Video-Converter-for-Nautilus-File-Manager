# Nautilus MenuProvider: Convert for Resolve / Convert MOV to MP4
# SCRIPT_PATH is rewritten by the installer.

from __future__ import annotations

import os
import subprocess
from typing import List

from gi.repository import GObject, Nautilus

# Patched at install time to the real converter path.
SCRIPT_PATH = os.path.expanduser("~/.local/bin/ffmpegconvert-resolve.sh")

ICON_CANDIDATES = (
    "/opt/resolve/graphics/DV_Panels.png",
    os.path.expanduser("~/.local/share/icons/DV_Panels.png"),
)


def _icon_name() -> str:
    for path in ICON_CANDIDATES:
        if os.path.isfile(path):
            return path
    return "video-x-generic"


def _local_path(file_info: Nautilus.FileInfo) -> str | None:
    location = file_info.get_location()
    if location is None:
        return None
    return location.get_path()


def _is_video_or_directory(file_info: Nautilus.FileInfo) -> bool:
    if file_info.is_directory():
        return True
    mime = file_info.get_mime_type() or ""
    return mime.startswith("video/")


def _is_mov(file_info: Nautilus.FileInfo) -> bool:
    if file_info.is_directory():
        return True
    name = (file_info.get_name() or "").lower()
    if name.endswith(".mov") or name.endswith(".qt"):
        return True
    mime = file_info.get_mime_type() or ""
    return mime in (
        "video/quicktime",
        "video/x-quicktime",
    )


def _spawn(args: List[str]) -> None:
    if not os.path.isfile(SCRIPT_PATH) or not os.access(SCRIPT_PATH, os.X_OK):
        return
    subprocess.Popen(args, start_new_session=True)


class ResolveConvertExtension(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self) -> None:
        super().__init__()

    def _paths(self, files: List[Nautilus.FileInfo]) -> List[str]:
        paths: List[str] = []
        for f in files:
            path = _local_path(f)
            if path:
                paths.append(path)
        return paths

    def _activate_resolve(
        self,
        _menu: Nautilus.MenuItem,
        files: List[Nautilus.FileInfo],
    ) -> None:
        paths = self._paths(files)
        if paths:
            _spawn([SCRIPT_PATH, *paths])

    def _activate_mov_to_mp4(
        self,
        _menu: Nautilus.MenuItem,
        files: List[Nautilus.FileInfo],
    ) -> None:
        paths = self._paths(files)
        if paths:
            _spawn([SCRIPT_PATH, "--to-mp4", *paths])

    def get_file_items(self, *args) -> List[Nautilus.MenuItem]:
        # Nautilus 3: (window, files); Nautilus 4: (files,)
        files = args[-1]
        if not files:
            return []

        items: List[Nautilus.MenuItem] = []

        if all(_is_video_or_directory(f) for f in files):
            resolve_item = Nautilus.MenuItem(
                name="ResolveConvertExtension::ConvertForResolve",
                label="Convert for Resolve",
                tip="Convert selected video(s) for DaVinci Resolve",
                icon=_icon_name(),
            )
            resolve_item.connect("activate", self._activate_resolve, files)
            items.append(resolve_item)

        if all(_is_mov(f) for f in files):
            mp4_item = Nautilus.MenuItem(
                name="ResolveConvertExtension::ConvertMovToMp4",
                label="Convert MOV to MP4",
                tip="Remux or convert QuickTime MOV to MP4",
                icon="video-x-generic",
            )
            mp4_item.connect("activate", self._activate_mov_to_mp4, files)
            items.append(mp4_item)

        return items

    def get_background_items(self, *args) -> List[Nautilus.MenuItem]:
        return []
