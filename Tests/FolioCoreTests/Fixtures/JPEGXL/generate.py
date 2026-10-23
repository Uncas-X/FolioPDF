"""Recreate the synthetic JPEG XL fixtures; not used by the app or test runner.

Generated with imagecodecs 2026.10.10 / libjxl 0.12.0 and numpy 2.5.4.
Install those tools in a disposable virtual environment to regenerate this data.
All source pixels are defined below; no external images or copyrighted assets.
"""
from pathlib import Path

import imagecodecs
import numpy as np

root = Path(__file__).resolve().parent
rgb = np.zeros((48, 80, 3), np.uint8)
rgb[:24, :40] = [255, 0, 0]
rgb[:24, 40:] = [0, 255, 0]
rgb[24:, :40] = [0, 0, 255]
rgb[24:, 40:] = [255, 255, 0]
rgba = np.zeros((48, 80, 4), np.uint8)
rgba[:, :, :3] = rgb
rgba[:24, :40, 3] = 255
rgba[:24, 40:, 3] = 128
rgba[24:, :40, 3] = 64
fixtures = [
    ("rgb-lossless.jxl", rgb, dict(lossless=True, usecontainer=False)),
    ("rgb-lossy.jxl", rgb, dict(lossless=False, distance=1, usecontainer=True)),
    ("rgba-lossless.jxl", rgba, dict(lossless=True, usecontainer=True)),
    ("gray16.jxl", np.tile(np.linspace(0, 65535, 80, dtype=np.uint16), (48, 1)),
     dict(lossless=True, usecontainer=True)),
    ("animation.jxl", np.stack([rgb, np.flip(rgb, axis=1)]), dict(lossless=True, usecontainer=True)),
]
for name, pixels, options in fixtures:
    encoded = imagecodecs.jpegxl_encode(pixels, **options)
    (root / name).write_bytes(encoded)
    if options["lossless"]:
        np.testing.assert_array_equal(imagecodecs.jpegxl_decode(encoded), pixels)
    print(name, len(encoded), "bytes", pixels.shape)
