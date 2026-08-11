#!/usr/bin/env bash
set -euo pipefail

python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -e .

echo "Potter 8.0 is installed in .venv"
echo "Next: export OPENAI_API_KEY=\"your_key\""
echo "Then: .venv/bin/potter chat"
