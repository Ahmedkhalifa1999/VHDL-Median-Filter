# Simulation harness (GHDL)

Scripts used to build and run the design on Linux with [GHDL](https://github.com/ghdl/ghdl).
They replace the MATLAB helpers, which do not run as committed (see `../REVIEW.md`).

```sh
apt-get install ghdl            # GHDL 4.1 was used
pip install numpy pillow

python3 sim/png_to_tb_input.py Unfiltered.png /tmp/UnfilteredImage.txt
sim/run_sim.sh . /tmp/build /tmp/UnfilteredImage.txt /tmp/FilteredImage.txt 08
python3 sim/tb_output_to_png.py /tmp/FilteredImage.txt /tmp/HW-Filtered.png
python3 sim/compare.py . /tmp/FilteredImage.txt
```

`compare.py` checks the RTL output against a software model of what the RTL is
designed to compute, against MATLAB's `medfilt2` conventions, and against the
PNGs committed in the repository.
