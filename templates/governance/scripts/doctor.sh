#!/usr/bin/env bash
set -euo pipefail

echo "== Governance System Template Doctor =="
echo

echo "-- OS --"
uname -a || true
echo

echo "-- Bun --"
if command -v bun >/dev/null 2>&1; then
  bun --version
else
  echo "bun: NOT FOUND"
fi
echo

echo "-- Node (break-glass) --"
if command -v node >/dev/null 2>&1; then
  node --version
else
  echo "node: NOT FOUND"
fi
echo

echo "-- Python --"
if command -v python >/dev/null 2>&1; then
  python --version
else
  echo "python: NOT FOUND"
fi
echo

echo "-- uv --"
if command -v uv >/dev/null 2>&1; then
  uv --version
else
  echo "uv: NOT FOUND"
fi
echo

echo "-- Rust --"
if command -v rustc >/dev/null 2>&1; then
  rustc --version
else
  echo "rustc: NOT FOUND"
fi
echo

echo "-- just --"
if command -v just >/dev/null 2>&1; then
  just --version
else
  echo "just: NOT FOUND"
fi
echo

echo "Next: run 'just ci'"
