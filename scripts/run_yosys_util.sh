#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="$ROOT_DIR/reports"
SKY130_LIB="/Users/kwashieandoh/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

mkdir -p "$REPORT_DIR"

if ! command -v yosys >/dev/null 2>&1; then
  echo "Error: yosys not found in PATH" >&2
  exit 1
fi

if [[ ! -f "$SKY130_LIB" ]]; then
  echo "Error: Sky130 lib not found at $SKY130_LIB" >&2
  exit 1
fi

yosys -Q -s "$ROOT_DIR/scripts/yosys_util.ys" | tee "$REPORT_DIR/yosys_util.txt"
