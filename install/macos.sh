#!/bin/bash
set -e
brew install imagemagick potrace
pip3 install --user vtracer   # --user avoids PEP 668
echo "Done. Usage: vectorize image.png   or   vectorize -c image.png"
