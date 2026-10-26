# Nautilus MenuProvider: Convert for Resolve
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
    path = location.get_path()
    return path


def _is_video_or_directory(file_info: Nautilus.FileInfo) -> bool:
    if file_info.is_directory():
        return True
    mime = file_info.get_mime_type() or ""
    return mime.startswith("video/")


class ResolveConvertExtension(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self) -> None:
        super().__init__()

    def _activate(
        self,
        _menu: Nautilus.MenuItem,
        files: List[Nautilus.FileInfo],
    ) -> None:
        paths: List[str] = []
        for f in files:
            path = _local_path(f)
            if path:
                paths.append(path)
        if not paths:
            return
        if not os.path.isfile(SCRIPT_PATH) or not os.access(SCRIPT_PATH, os.X_OK):
            return
        subprocess.Popen(
            [SCRIPT_PATH, *paths],
            start_new_session=True,
        )

    def get_file_items(self, *args) -> List[Nautilus.MenuItem]:
        # Nautilus 3: (window, files); Nautilus 4: (files,)
        files = args[-1]
        if not files:
            return []
        if not all(_is_video_or_directory(f) for f in files):
            return []

        item = Nautilus.MenuItem(
            name="ResolveConvertExtension::ConvertForResolve",
            label="Convert for Resolve",
            tip="Convert selected video(s) for DaVinci Resolve",
            icon=_icon_name(),
        )
        item.connect("activate", self._activate, files)
        return [item]

    def get_background_items(self, *args) -> List[Nautilus.MenuItem]:
        return []
