#!/usr/bin/env bash
set -x

ROOT_DIR="$(pwd)"
OUTPUT_DIR="$(pwd)/dist"
LAYER_DIR=$OUTPUT_DIR/layers/nodejs
mkdir -p $LAYER_DIR
cp -LR node_modules $LAYER_DIR
cd $OUTPUT_DIR/layers
zip -r layers.zip nodejs