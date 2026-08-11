.PHONY: install test run serve ios

install:
	python3 -m venv .venv
	.venv/bin/python -m pip install --upgrade pip
	.venv/bin/python -m pip install -e .

test:
	python3 -m unittest discover -s tests -v

run:
	.venv/bin/python potter.py

serve:
	.venv/bin/python potter.py serve --host 0.0.0.0

ios:
	cd ios/Potter8 && xcodegen generate
