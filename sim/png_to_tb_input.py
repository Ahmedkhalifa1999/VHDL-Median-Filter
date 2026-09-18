#!/usr/bin/env python3
"""Replacement for InputImage.m: turn a 100x100 grayscale PNG into the
2400-bit-per-line text file that TestBench.vhd reads.

Line i (0-based) holds rows i-1, i, i+1 of the image, each pixel as 8 bits
MSB first. Rows -1 and 100 are zero padding, which is what the RTL relies on
for its edge-pixel median positions.
"""
import sys
from PIL import Image
import numpy as np

src, dst = sys.argv[1], sys.argv[2]
img = np.array(Image.open(src).convert("L"), dtype=np.uint8)
assert img.shape == (100, 100), img.shape
padded = np.zeros((102, 100), dtype=np.uint8)
padded[1:101, :] = img
with open(dst, "w") as f:
    for i in range(100):
        bits = "".join(format(int(p), "08b") for r in (i, i + 1, i + 2) for p in padded[r])
        assert len(bits) == 2400
        f.write(bits + "\n")
print(f"wrote {dst}: 100 lines x 2400 bits")
