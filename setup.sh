#!/usr/bin/env bash
set -euo pipefail

python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -e .

echo "Potter 8.0 is installed in .venv"
echo "Free local: install Ollama, run 'ollama pull gemma3:4b', then use model ollama-local-free"
echo "Hosted AI: export only the provider key you own (OPENAI_API_KEY, GEMINI_API_KEY, etc.)"
echo "Start: .venv/bin/potter chat, then enter /models"
