#!/bin/bash
#SBATCH --job-name=dismech_follow
#SBATCH --output=./output/slurm_%j.out
#SBATCH --error=./output/slurm_%j.err
#SBATCH --partition=gpu_batch
#SBATCH --gres=gpu:1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=7-00:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=your_email@example.com

# SLURM script for training DisMech Follow Task with SAC
# Usage: sbatch train_follow_dismech.slurm [output_dir] [num_envs] [ws_dim] [gpu_id]

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Parse arguments (SLURM passes them differently, so we'll use environment variables)
# You can override these by setting them before sbatch:
# export OUTPUT_DIR=./my_output; export NUM_ENVS=500; sbatch train_follow_dismech.slurm
OUTPUT_DIR="${OUTPUT_DIR:-./output/follow_dismech_$(date +%Y%m%d_%H%M%S)}"
NUM_ENVS="${NUM_ENVS:-500}"
WS_DIM="${WS_DIM:-3}"
GPU_ID="${SLURM_LOCALID:-0}"  # Use SLURM's local task ID for GPU
UTD_RATIO="${UTD_RATIO:-4}"

# Set environment variables
export OMP_NUM_THREADS=1
export CUDA_VISIBLE_DEVICES=$GPU_ID

# Print job information
echo "=========================================="
echo "SLURM Job Information"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Job Name: $SLURM_JOB_NAME"
echo "Node: $SLURM_NODELIST"
echo "GPU: $GPU_ID"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "Memory: $SLURM_MEM_PER_NODE MB"
echo "=========================================="
echo ""
echo "Training Configuration:"
echo "Output directory: $OUTPUT_DIR"
echo "Number of parallel environments: $NUM_ENVS"
echo "Workspace dimension: $WS_DIM"
echo "UTD ratio: $UTD_RATIO"
echo "=========================================="
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Print start time
echo "Job started at: $(date)"
echo ""

# Run training
python -m alf.bin.train \
    --conf "$SCRIPT_DIR/dismech-rl/confs/follow_conf.py" \
    --root_dir "$OUTPUT_DIR" \
    --conf_param "sim_framework='dismech'" \
    --conf_param "ws_dim=$WS_DIM" \
    --conf_param "DisMechFollowEnv.render=False" \
    --conf_param "create_environment.num_parallel_environments=$NUM_ENVS" \
    --conf_param "utd_ratio=$UTD_RATIO"

# Print end time and status
echo ""
echo "Job finished at: $(date)"
echo ""
echo "Training completed. Results saved to: $OUTPUT_DIR"
echo "Log files:"
echo "  - SLURM output: ./output/slurm_${SLURM_JOB_ID}.out"
echo "  - SLURM error: ./output/slurm_${SLURM_JOB_ID}.err"
echo "  - Training logs: $OUTPUT_DIR/py_train.*"
echo ""
echo "To monitor training with TensorBoard:"
echo "  ./start_tensorboard_slurm.sh $OUTPUT_DIR"

