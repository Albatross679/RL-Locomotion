#!/bin/bash

# Training script for DisMech Follow Task with SAC
# Usage: ./train_follow_dismech.sh [output_dir] [num_envs] [ws_dim] [render] [utd_ratio] [gpu_ids] [use_multi_gpu]

# Set default values
OUTPUT_DIR="${1:-./output/follow_dismech_$(date +%Y%m%d_%H%M%S)}"
NUM_ENVS="${2:-500}"
WS_DIM="${3:-3}"
RENDER="${4:-False}"
UTD_RATIO="${5:-4}"
GPU_IDS="${6:-0}"  # Default to GPU 0, use comma-separated for multiple: "0,1,2,3"
USE_MULTI_GPU="${7:-false}"  # Set to "true" for distributed multi-GPU training

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set environment variables
export OMP_NUM_THREADS=1

# GPU Configuration
if [ "$USE_MULTI_GPU" = "true" ]; then
    export CUDA_VISIBLE_DEVICES="$GPU_IDS"
    DISTRIBUTED_FLAG="--distributed multi-gpu"
    echo "Using multi-GPU training with GPUs: $GPU_IDS"
else
    export CUDA_VISIBLE_DEVICES="$GPU_IDS"
    DISTRIBUTED_FLAG=""
    echo "Using single GPU: $GPU_IDS"
fi

# Print configuration
echo "=========================================="
echo "Training DisMech Follow Task with SAC"
echo "=========================================="
echo "Output directory: $OUTPUT_DIR"
echo "Number of parallel environments: $NUM_ENVS"
echo "Workspace dimension: $WS_DIM"
echo "Render: $RENDER"
echo "UTD ratio: $UTD_RATIO"
echo "GPU IDs: $GPU_IDS"
echo "Multi-GPU: $USE_MULTI_GPU"
echo "=========================================="
echo ""

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Build training command
TRAIN_CMD="python -m alf.bin.train \
    --conf \"$SCRIPT_DIR/dismech-rl/confs/follow_conf.py\" \
    --root_dir \"$OUTPUT_DIR\" \
    --conf_param \"sim_framework='dismech'\" \
    --conf_param \"ws_dim=$WS_DIM\" \
    --conf_param \"DisMechFollowEnv.render=$RENDER\" \
    --conf_param \"create_environment.num_parallel_environments=$NUM_ENVS\" \
    --conf_param \"utd_ratio=$UTD_RATIO\""

# Add distributed flag if multi-GPU
if [ "$USE_MULTI_GPU" = "true" ]; then
    TRAIN_CMD="$TRAIN_CMD --distributed multi-gpu"
fi

# Run training
eval $TRAIN_CMD

echo ""
echo "Training completed. Results saved to: $OUTPUT_DIR"
echo "To monitor training, run: tensorboard --logdir $OUTPUT_DIR"
echo ""
echo "Log files location:"
echo "  - Info logs: $OUTPUT_DIR/py_train.INFO"
echo "  - Error logs: $OUTPUT_DIR/py_train.ERROR"
echo "  - Warning logs: $OUTPUT_DIR/py_train.WARNING"
echo ""
echo "To view errors: tail -f $OUTPUT_DIR/py_train.ERROR"

