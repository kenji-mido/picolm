#!/bin/bash
# test_wasm.sh - Test picolm WASM build on WAMR (iwasm)
#
# Prerequisites:
#   1. wasi-sdk:  https://github.com/WebAssembly/wasi-sdk/releases
#   2. iwasm:     https://github.com/bytecodealliance/wasm-micro-runtime/releases
#   3. Model:     make model  (or download TinyLlama Q4_K_M manually)
#
# Usage:
#   ./test_wasm.sh [model.gguf]

set -e

MODEL="${1:-/tmp/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf}"
IWASM="${IWASM:-iwasm}"
WASI_SDK="${WASI_SDK:-/opt/wasi-sdk}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Check prerequisites ---

if ! command -v "$IWASM" &>/dev/null; then
    echo "Error: iwasm not found. Set IWASM=/path/to/iwasm or install it:"
    echo "  https://github.com/bytecodealliance/wasm-micro-runtime/releases"
    exit 1
fi

if [ ! -f "$MODEL" ]; then
    echo "Error: Model not found: $MODEL"
    echo "Download with:  make model"
    echo "Or specify:     $0 /path/to/model.gguf"
    exit 1
fi

# --- Build if needed ---

if [ ! -f "$SCRIPT_DIR/picolm.wasm" ]; then
    echo "Building picolm.wasm..."
    WASI_SDK="$WASI_SDK" make -C "$SCRIPT_DIR" wasm
fi

# --- Run test ---

MODEL_DIR="$(dirname "$MODEL")"

echo "=== WASM test ==="
echo "iwasm:  $($IWASM --version 2>&1 | head -1)"
echo "model:  $MODEL"
echo ""

"$IWASM" --dir="$MODEL_DIR" "$SCRIPT_DIR/picolm.wasm" "$MODEL" -n 50 -p "<|im_start|>user
Explain gravity in one sentence.<|im_end|>
<|im_start|>assistant
"

echo ""
echo "=== Native comparison ==="

if [ ! -f "$SCRIPT_DIR/picolm" ]; then
    echo "Building native picolm..."
    make -C "$SCRIPT_DIR" native
fi

"$SCRIPT_DIR/picolm" "$MODEL" -n 50 -j 1 -p "<|im_start|>user
Explain gravity in one sentence.<|im_end|>
<|im_start|>assistant
"
