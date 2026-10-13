#!/usr/bin/env python3
"""PNG → SVG vectorizer: black (potrace) or color (-c, vtracer).

Black path uses ImageMagick (`magick`/`convert`) to make a grayscale PGM,
then potrace to trace it. Color path delegates to vtracer for per-layer
color tracing (potrace cannot produce multi-color regions).
"""
import argparse, shutil, subprocess, sys
from pathlib import Path

def vectorize(inp: str, out: str | None = None, color: bool = False) -> str:
    inp = Path(inp)
    if out is None:
        out = str(inp.with_suffix(".svg"))

    if color:
        if not shutil.which("vtracer"):
            print("color tracing needs vtracer: pip install --user vtracer",
                  file=sys.stderr); sys.exit(1)
        subprocess.run([
            "vtracer", "--input", str(inp), "--output", out,
            "--colormode", "color", "--mode", "spline",
        ], check=True)
        print(f"→ {out}")
        return out

    if not shutil.which("potrace"):
        print("install potrace + imagemagick (see install/)", file=sys.stderr)
        sys.exit(1)
    conv = "magick" if shutil.which("magick") else "convert"
    tmp = inp.with_suffix(".pgm")
    subprocess.run([
        conv, str(inp), "-flatten", "-grayscale", "Rec709Luminance",
        "-threshold", "50%", str(tmp),
    ], check=True)
    subprocess.run(["potrace", str(tmp), "-s", "-o", out], check=True)
    tmp.unlink(missing_ok=True)
    print(f"→ {out}")
    return out

if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Vectorize raster → SVG")
    ap.add_argument("input", help="Input PNG file")
    ap.add_argument("-o", "--output", help="Output SVG path")
    ap.add_argument("-c", "--color", action="store_true",
                    help="Color layers via vtracer")
    args = ap.parse_args()
    vectorize(args.input, args.output, args.color)
