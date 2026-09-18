#!/usr/bin/env python3
"""Replacement for OutputImage.m: decode the 800-bit-per-line testbench
output into a 100x100 grayscale PNG. Reports any non-binary characters
(e.g. 'U' or 'X') the simulator emitted."""
import sys
from PIL import Image
import numpy as np

src, dst = sys.argv[1], sys.argv[2]
rows = []
bad = 0
with open(src) as f:
    for ln, line in enumerate(f):
        line = line.strip()
        assert len(line) == 800, (ln, len(line))
        px = []
        for j in range(100):
            chunk = line[j * 8:(j + 1) * 8]
            if set(chunk) - {"0", "1"}:
                bad += 1
                px.append(0)
            else:
                px.append(int(chunk, 2))
        rows.append(px)
arr = np.array(rows, dtype=np.uint8)
Image.fromarray(arr).save(dst)
print(f"decoded {arr.shape} -> {dst}; pixels with non-01 chars: {bad}")
