#!env bash
# Symlynk python3 to conda python

ln -sf "$CONDA_PREFIX/bin/python" "$CONDA_PREFIX/bin/python3"

exit 0