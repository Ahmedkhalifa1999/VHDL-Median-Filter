#!/usr/bin/env python3
"""Compare the RTL output against software reference models and against the
PNGs committed in the repository."""
import sys
import numpy as np
from PIL import Image

repo, hw_txt = sys.argv[1], sys.argv[2]
src = np.array(Image.open(f"{repo}/Unfiltered.png").convert("L"), dtype=np.int32)
committed = np.array(Image.open(f"{repo}/Filtered.png").convert("L"), dtype=np.int32)
matlab = np.array(Image.open(f"{repo}/MATLAB-Filtered.png").convert("L"), dtype=np.int32)

hw = np.zeros((100, 100), dtype=np.int32)
with open(hw_txt) as f:
    for i, line in enumerate(f):
        line = line.strip()
        for j in range(100):
            hw[i, j] = int(line[j * 8:(j + 1) * 8], 2)

H, W = src.shape

def rtl_model(img):
    """What the RTL is designed to compute: for each pixel, the k-th largest of
    the *valid* 3x3 neighbours with k = ceil(n/2) (upper median for even n)."""
    out = np.zeros_like(img)
    for i in range(H):
        for j in range(W):
            win = img[max(0, i - 1):i + 2, max(0, j - 1):j + 2].ravel()
            out[i, j] = np.sort(win)[len(win) // 2]
    return out

def medfilt_zero_pad(img):
    """MATLAB medfilt2 default: 3x3 median with zero padding (always 9 values)."""
    p = np.pad(img, 1, mode="constant", constant_values=0)
    out = np.zeros_like(img)
    for i in range(H):
        for j in range(W):
            out[i, j] = np.sort(p[i:i + 3, j:j + 3].ravel())[4]
    return out

def medfilt_sym_pad(img):
    """medfilt2(...,'symmetric')."""
    p = np.pad(img, 1, mode="symmetric")
    out = np.zeros_like(img)
    for i in range(H):
        for j in range(W):
            out[i, j] = np.sort(p[i:i + 3, j:j + 3].ravel())[4]
    return out

ref = rtl_model(src)
mz = medfilt_zero_pad(src)
ms = medfilt_sym_pad(src)

def report(name, a, b):
    d = a != b
    interior = d[1:-1, 1:-1].sum()
    border = d.sum() - interior
    print(f"{name:55s} mismatches: total={d.sum():5d}  interior={interior:5d}  border={border:4d}  max|diff|={np.abs(a-b).max():3d}")

report("HW (GHDL) vs RTL-intent model (upper median of valid px)", hw, ref)
report("HW (GHDL) vs committed Filtered.png", hw, committed)
report("HW (GHDL) vs medfilt2 zero-pad reference", hw, mz)
report("HW (GHDL) vs medfilt2 symmetric-pad reference", hw, ms)
report("committed Filtered.png vs committed MATLAB-Filtered.png", committed, matlab)
report("committed MATLAB-Filtered.png vs medfilt2 zero-pad", matlab, mz)
report("committed MATLAB-Filtered.png vs medfilt2 symmetric-pad", matlab, ms)
report("committed Filtered.png vs RTL-intent model", committed, ref)
print("noise pixels (0 or 255) in input :", int(((src == 0) | (src == 255)).sum()))
print("noise pixels (0 or 255) in HW out:", int(((hw == 0) | (hw == 255)).sum()))
