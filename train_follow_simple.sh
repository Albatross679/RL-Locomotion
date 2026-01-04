#!/bin/bash

# Simple training script for DisMech Follow Task with SAC
# Usage: ./train_follow_simple.sh
# Note: ALF automatically uses GPU if CUDA is available

# Set environment variables
export OMP_NUM_THREADS=1

# GPU Configuration (ALF will auto-detect and use GPU 0 by default)
# To use specific GPU(s), uncomment and modify:
# export CUDA_VISIBLE_DEVICES=0  # Use GPU 0
# export CUDA_VISIBLE_DEVICES=0,1,2,3  # Use multiple GPUs

# Default output directory with timestamp
OUTPUT_DIR="./output/follow_$(date +%Y%m%d_%H%M%S)"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run training
python -m alf.bin.train \
    --conf "$SCRIPT_DIR/dismech-rl/confs/follow_conf.py" \
    --root_dir "$OUTPUT_DIR" \
    --conf_param "sim_framework='dismech'"

echo "Training started. Monitor with: tensorboard --logdir $OUTPUT_DIR"

