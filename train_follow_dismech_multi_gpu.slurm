#!/bin/bash
#SBATCH --job-name=dismech_follow_mgpu
#SBATCH --output=./output/slurm_%j.out
#SBATCH --error=./output/slurm_%j.err
#SBATCH --partition=gpu_batch
#SBATCH --gres=gpu:4
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=7-00:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=wen.679@osu.edu

# SLURM script for multi-GPU training DisMech Follow Task with SAC
# 
# Usage:
#   Start new training: sbatch train_follow_dismech_multi_gpu.slurm
#   Resume training:    OUTPUT_DIR=/path/to/existing/output sbatch train_follow_dismech_multi_gpu.slurm
# 
# To resume training, set OUTPUT_DIR to an existing training directory.
# The script will automatically detect and load the latest checkpoint.

# Get script directory - use absolute path to workspace
# This ensures we use the actual workspace directory, not SLURM's spool directory
SCRIPT_DIR="${RL_LOCOMOTION_DIR:-/home/wen.679/RL_locomotion}"
cd "$SCRIPT_DIR"

# Verify we're in the right directory
if [ ! -f "$SCRIPT_DIR/train_follow_dismech_multi_gpu.slurm" ]; then
    echo "ERROR: Cannot find train_follow_dismech_multi_gpu.slurm in $SCRIPT_DIR"
    echo "Please set RL_LOCOMOTION_DIR environment variable or update the path in the script"
    exit 1
fi

# Create output directory early (before SLURM tries to redirect logs)
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

# Set PYTHONPATH (adjust paths as needed for your installation)
export PYTHONPATH="${PYTHONPATH}:${SCRIPT_DIR}/dismech-rods:${SCRIPT_DIR}/alf:${SCRIPT_DIR}/dismech-rl"

# Parse arguments - use absolute path for output directory
# If OUTPUT_DIR is not set, create a new directory with timestamp
# If OUTPUT_DIR is set to an existing directory, training will resume from checkpoint
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="${SCRIPT_DIR}/output/follow_dismech_mgpu_$(date +%Y%m%d_%H%M%S)"
    RESUME_MODE=false
else
    # Convert to absolute path if relative
    if [[ ! "$OUTPUT_DIR" = /* ]]; then
        OUTPUT_DIR="${SCRIPT_DIR}/${OUTPUT_DIR}"
    fi
    RESUME_MODE=true
fi

NUM_ENVS="${NUM_ENVS:-500}"
WS_DIM="${WS_DIM:-3}"
UTD_RATIO="${UTD_RATIO:-4}"
NUM_ITERATIONS="${NUM_ITERATIONS:-4000}"

# Check if resuming and if checkpoint exists
CHECKPOINT_DIR="${OUTPUT_DIR}/train/algorithm"
if [ "$RESUME_MODE" = true ]; then
    if [ ! -d "$OUTPUT_DIR" ]; then
        echo "ERROR: Output directory does not exist: $OUTPUT_DIR"
        echo "Please provide a valid existing training directory to resume, or"
        echo "unset OUTPUT_DIR to start a new training run."
        exit 1
    fi
    if [ -d "$CHECKPOINT_DIR" ] && [ -n "$(ls -A "$CHECKPOINT_DIR"/ckpt-* 2>/dev/null)" ]; then
        echo "Resume mode: Found existing checkpoints in $CHECKPOINT_DIR"
        LATEST_CKPT=$(ls -t "$CHECKPOINT_DIR"/ckpt-* 2>/dev/null | head -1 | sed 's/.*ckpt-//' | sed 's/-.*$//')
        echo "Latest checkpoint: ckpt-$LATEST_CKPT"
    else
        echo "WARNING: Resume mode enabled but no checkpoints found in $CHECKPOINT_DIR"
        echo "Training will start from scratch in the existing directory."
    fi
else
    echo "Starting new training run."
fi

# Set environment variables
export OMP_NUM_THREADS=1
export CUDA_VISIBLE_DEVICES=0,1,2,3  # Use all 4 GPUs
# Required for deterministic CuBLAS operations when torch.use_deterministic_algorithms(True) is enabled
export CUBLAS_WORKSPACE_CONFIG=:4096:8

# Print job information
echo "=========================================="
echo "SLURM Multi-GPU Job Information"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Job Name: $SLURM_JOB_NAME"
echo "Node: $SLURM_NODELIST"
echo "GPUs: 0,1,2,3 (all 4 GPUs)"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "Memory: $SLURM_MEM_PER_NODE MB"
echo "Python: $(python --version)"
echo "Python path: $(which python)"
echo "=========================================="
echo ""
echo "Training Configuration:"
echo "Mode: $([ "$RESUME_MODE" = true ] && echo "RESUME" || echo "NEW TRAINING")"
echo "Output directory: $OUTPUT_DIR"
echo "Number of parallel environments: $NUM_ENVS"
echo "Workspace dimension: $WS_DIM"
echo "UTD ratio: $UTD_RATIO"
echo "Number of iterations: $NUM_ITERATIONS"
echo "Multi-GPU: Enabled"
echo "=========================================="
echo ""

# Create output directory (only creates if it doesn't exist)
mkdir -p "$OUTPUT_DIR"

# Function to print resume command
print_resume_command() {
    echo ""
    echo "=========================================="
    echo "To resume training, run:"
    echo "  OUTPUT_DIR=\"$OUTPUT_DIR\" \\"
    echo "  NUM_ITERATIONS=${NUM_ITERATIONS} \\"
    echo "  sbatch $SCRIPT_DIR/train_follow_dismech_multi_gpu.slurm"
    echo ""
    echo "Or simply:"
    echo "  OUTPUT_DIR=\"$OUTPUT_DIR\" sbatch $SCRIPT_DIR/train_follow_dismech_multi_gpu.slurm"
    echo "=========================================="
}

# Set trap to print resume command on exit (normal or interrupted)
trap print_resume_command EXIT

# Print start time
echo "Job started at: $(date)"
echo ""
echo "To monitor training with TensorBoard:"
echo "  ./start_tensorboard_slurm.sh $OUTPUT_DIR"
echo ""

# Run training with multi-GPU (using conda Python 3.12)
python -m alf.bin.train \
    --conf "$SCRIPT_DIR/dismech-rl/confs/follow_conf.py" \
    --root_dir "$OUTPUT_DIR" \
    --conf_param "sim_framework='dismech'" \
    --conf_param "_CONFIG._USER.ws_dim=$WS_DIM" \
    --conf_param "DisMechFollowEnv.render=False" \
    --conf_param "create_environment.num_parallel_environments=$NUM_ENVS" \
    --conf_param "utd_ratio=$UTD_RATIO" \
    --conf_param "TrainerConfig.num_iterations=$NUM_ITERATIONS" \
    --distributed multi-gpu

# Capture exit code from training
TRAIN_EXIT_CODE=$?

# Print end time and status
echo ""
echo "Job finished at: $(date)"
echo ""
if [ $TRAIN_EXIT_CODE -eq 0 ]; then
    echo "Training completed successfully. Results saved to: $OUTPUT_DIR"
else
    echo "Training exited with code $TRAIN_EXIT_CODE. Check logs for details."
    echo "Results saved to: $OUTPUT_DIR"
fi
echo "Log files:"
echo "  - SLURM output: ${SCRIPT_DIR}/output/slurm_${SLURM_JOB_ID}.out"
echo "  - SLURM error: ${SCRIPT_DIR}/output/slurm_${SLURM_JOB_ID}.err"
echo "  - Training logs: $OUTPUT_DIR/py_train.*"
echo ""

# The resume command will be printed by the EXIT trap

