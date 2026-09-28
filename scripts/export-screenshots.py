#!/usr/bin/env python3
"""Copies the README screenshots attached by ScreenshotUITests out of a result bundle.

Usage: python3 scripts/export-screenshots.py build/UITests.xcresult docs/screenshots
Requires Xcode 16+ (`xcrun xcresulttool export attachments`).
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile


def main(result_bundle, destination):
    work = tempfile.mkdtemp()
    subprocess.run(
        ["xcrun", "xcresulttool", "export", "attachments", "--path", result_bundle, "--output-path", work],
        check=True,
    )
    with open(os.path.join(work, "manifest.json")) as f:
        manifest = json.load(f)
    os.makedirs(destination, exist_ok=True)
    exported = 0
    for test in manifest:
        for attachment in test.get("attachments", []):
            name = attachment.get("suggestedHumanReadableName", "")
            if not name.startswith("readme-"):
                continue
            # e.g. "readme-01-compact_0_1A2B….png" -> "01-compact.png"
            base = name[len("readme-"):].split("_")[0]
            base = os.path.splitext(base)[0]
            shutil.copyfile(os.path.join(work, attachment["exportedFileName"]), os.path.join(destination, base + ".png"))
            print("exported", base + ".png")
            exported += 1
    if exported == 0:
        sys.exit("error: no readme- screenshots found in " + result_bundle)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
