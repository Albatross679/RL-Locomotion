#!/bin/bash
#SBATCH --job-name=eval_policy
#SBATCH --output=./output/slurm_eval_%j.out
#SBATCH --error=./output/slurm_eval_%j.err
#SBATCH --partition=gpu_batch
#SBATCH --gres=gpu:1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=2-00:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=wen.679@osu.edu

# SLURM script to evaluate/test a trained policy using alf.bin.play
# 
# Usage:
#   OUTPUT_DIR="/home/wen.679/RL_locomotion/output/follow_dismech_mgpu_20260103_214930" \
#   CHECKPOINT_STEP=20001 \
#   NUM_EPISODES=10 \
#   sbatch evaluate_policy.slurm
#
# With video recording:
#   OUTPUT_DIR="/home/wen.679/RL_locomotion/output/follow_dismech_mgpu_20260103_214930" \
#   CHECKPOINT_STEP=20001 \
#   NUM_EPISODES=1 \
#   RECORD_FILE="/home/wen.679/RL_locomotion/output/policy_evaluation.mp4" \
#   sbatch evaluate_policy.slurm

# Get script directory
SCRIPT_DIR="${RL_LOCOMOTION_DIR:-/home/wen.679/RL_locomotion}"
cd "$SCRIPT_DIR"

# Verify we're in the right directory
if [ ! -f "$SCRIPT_DIR/evaluate_policy.slurm" ]; then
    echo "ERROR: Cannot find evaluate_policy.slurm in $SCRIPT_DIR"
    echo "Please set RL_LOCOMOTION_DIR environment variable or update the path in the script"
    exit 1
fi

# Create output directory
mkdir -p "${SCRIPT_DIR}/output"

# Initialize conda and activate environment
source ~/miniconda3/etc/profile.d/conda.sh
conda activate rl-locomotion

# Set Boost include and library paths from conda environment
if [ -n "$CONDA_PREFIX" ]; then
    export CPLUS_INCLUDE_PATH="${CONDA_PREFIX}/include:${CPLUS_INCLUDE_PATH}"
    export LIBRARY_PATH="${CONDA_PREFIX}/lib:${LIBRARY_PATH}"
    export LD_LIBRARY_PATH="${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH}"
fi

# Set PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:${SCRIPT_DIR}/dismech-rods:${SCRIPT_DIR}/alf:${SCRIPT_DIR}/dismech-rl"

# Set default values
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/output/follow_dismech_mgpu_20260103_214930}"
CHECKPOINT_STEP="${CHECKPOINT_STEP:-latest}"
NUM_EPISODES="${NUM_EPISODES:-10}"
WS_DIM="${WS_DIM:-3}"
RECORD_FILE="${RECORD_FILE:-}"

# Convert to absolute path if relative
if [[ ! "$OUTPUT_DIR" = /* ]]; then
    OUTPUT_DIR="${SCRIPT_DIR}/${OUTPUT_DIR}"
fi

# Validate output directory exists
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "ERROR: Output directory does not exist: $OUTPUT_DIR"
    echo "Please provide a valid OUTPUT_DIR path"
    exit 1
fi

# Validate checkpoint directory exists
CHECKPOINT_DIR="${OUTPUT_DIR}/train/algorithm"
if [ ! -d "$CHECKPOINT_DIR" ]; then
    echo "ERROR: Checkpoint directory does not exist: $CHECKPOINT_DIR"
    echo "Please provide a valid training output directory"
    exit 1
fi

# Check if checkpoints exist
if [ -z "$(ls -A "$CHECKPOINT_DIR"/ckpt-* 2>/dev/null)" ]; then
    echo "ERROR: No checkpoints found in $CHECKPOINT_DIR"
    echo "Please ensure the training has created checkpoints"
    exit 1
fi

# Find available checkpoints
AVAILABLE_CKPTS=$(ls "$CHECKPOINT_DIR"/ckpt-* 2>/dev/null | grep -v optimizer | grep -v replay_buffer | sed 's/.*ckpt-//' | sort -n)
LATEST_CKPT=$(echo "$AVAILABLE_CKPTS" | tail -1)

echo "Available checkpoints: $(echo $AVAILABLE_CKPTS | tr '\n' ' ')"
echo "Latest checkpoint: ckpt-$LATEST_CKPT"

# If checkpoint_step is 'latest', use the latest checkpoint number
if [ "$CHECKPOINT_STEP" = "latest" ]; then
    CHECKPOINT_STEP="$LATEST_CKPT"
    echo "Using latest checkpoint: ckpt-$CHECKPOINT_STEP"
fi

# Set environment variables
export OMP_NUM_THREADS=1
export CUDA_VISIBLE_DEVICES=0  # Use single GPU for evaluation
export CUBLAS_WORKSPACE_CONFIG=:4096:8
# Set matplotlib backend to Agg for headless execution (no display server required)
export MPLBACKEND=Agg

# Print job information
echo "=========================================="
echo "Policy Evaluation SLURM Job Information"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Job Name: $SLURM_JOB_NAME"
echo "Node: $SLURM_NODELIST"
echo "GPU: 0"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "Memory: $SLURM_MEM_PER_NODE MB"
echo "Python: $(python --version)"
echo "Python path: $(which python)"
echo "=========================================="
echo ""
echo "Evaluation Configuration:"
echo "Output directory: $OUTPUT_DIR"
echo "Checkpoint: ckpt-$CHECKPOINT_STEP"
echo "Number of episodes: $NUM_EPISODES"
echo "Workspace dimension: $WS_DIM"
if [ -n "$RECORD_FILE" ]; then
    echo "Recording video to: $RECORD_FILE"
    RENDER_FLAG=""
else
    echo "Rendering: Disabled (headless evaluation)"
    RENDER_FLAG="--norender"
fi
echo "=========================================="
echo ""

echo "Job started at: $(date)"
echo ""

# Build play command
PLAY_CMD="python -m alf.bin.play \
    --conf \"$SCRIPT_DIR/dismech-rl/confs/follow_conf.py\" \
    --root_dir \"$OUTPUT_DIR\" \
    --conf_param \"sim_framework='dismech'\" \
    --conf_param \"_CONFIG._USER.ws_dim=$WS_DIM\" \
    --conf_param \"DisMechFollowEnv.render=False\" \
    --checkpoint_step $CHECKPOINT_STEP \
    --num_episodes $NUM_EPISODES \
    $RENDER_FLAG"

# Add record_file if specified
if [ -n "$RECORD_FILE" ]; then
    # Convert to absolute path if relative
    if [[ ! "$RECORD_FILE" = /* ]]; then
        RECORD_FILE="${SCRIPT_DIR}/${RECORD_FILE}"
    fi
    # Create directory for video if it doesn't exist
    mkdir -p "$(dirname "$RECORD_FILE")"
    PLAY_CMD="$PLAY_CMD --record_file \"$RECORD_FILE\""
fi

echo "Running evaluation command:"
echo "$PLAY_CMD"
echo ""

# Run evaluation
eval $PLAY_CMD

# Capture exit code
EVAL_EXIT_CODE=$?

echo ""
echo "Job finished at: $(date)"
echo ""

if [ $EVAL_EXIT_CODE -eq 0 ]; then
    echo "Evaluation completed successfully!"
    if [ -n "$RECORD_FILE" ] && [ -f "$RECORD_FILE" ]; then
        echo "Video saved to: $RECORD_FILE"
    fi
else
    echo "Evaluation exited with code $EVAL_EXIT_CODE. Check logs for details."
fi

echo ""
echo "Log files:"
echo "  - SLURM output: ${SCRIPT_DIR}/output/slurm_eval_${SLURM_JOB_ID}.out"
echo "  - SLURM error: ${SCRIPT_DIR}/output/slurm_eval_${SLURM_JOB_ID}.err"
echo ""


