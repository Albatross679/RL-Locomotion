#!/bin/bash
#SBATCH --job-name=tensorboard_view
#SBATCH --output=./output/slurm_tensorboard_%j.out
#SBATCH --error=./output/slurm_tensorboard_%j.err
#SBATCH --partition=cpu_batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=7-00:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=wen.679@osu.edu

# SLURM script to run TensorBoard for viewing training metrics
# 
# Usage:
#   LOG_DIR="/home/wen.679/RL_locomotion/output/follow_dismech_mgpu_20260103_214930" \
#   PORT=6007 \
#   sbatch tensorboard_view.slurm
#
# Or simply:
#   LOG_DIR="/home/wen.679/RL_locomotion/output/follow_dismech_mgpu_20260103_214930" \
#   sbatch tensorboard_view.slurm

# Get script directory
SCRIPT_DIR="${RL_LOCOMOTION_DIR:-/home/wen.679/RL_locomotion}"
cd "$SCRIPT_DIR"

# Create output directory
mkdir -p "${SCRIPT_DIR}/output"

# Initialize conda and activate environment
source ~/miniconda3/etc/profile.d/conda.sh
conda activate rl-locomotion

# Set default values
LOG_DIR="${LOG_DIR:-${SCRIPT_DIR}/output/follow_dismech_mgpu_20260103_214930}"
PORT="${PORT:-6006}"

# Convert to absolute path if relative
if [[ ! "$LOG_DIR" = /* ]]; then
    LOG_DIR="${SCRIPT_DIR}/${LOG_DIR}"
fi

# Validate log directory exists
if [ ! -d "$LOG_DIR" ]; then
    echo "ERROR: Log directory does not exist: $LOG_DIR"
    echo "Please provide a valid LOG_DIR path"
    exit 1
fi

# Print job information
echo "=========================================="
echo "TensorBoard SLURM Job Information"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Job Name: $SLURM_JOB_NAME"
echo "Node: $SLURM_NODELIST"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "Memory: $SLURM_MEM_PER_NODE MB"
echo "Python: $(python --version)"
echo "=========================================="
echo ""
echo "TensorBoard Configuration:"
echo "Log directory: $LOG_DIR"
echo "Port: $PORT"
echo "=========================================="
echo ""

# Get node name
NODE_NAME=$(scontrol show hostname $SLURM_NODELIST | head -n 1)

echo "Job started at: $(date)"
echo ""
echo "TensorBoard is starting..."
echo ""
echo "=========================================="
echo "To access TensorBoard:"
echo "=========================================="
echo ""
echo "1. Set up SSH port forwarding on your local machine:"
echo "   ssh -L $PORT:${NODE_NAME}:$PORT ${USER}@$(hostname -f)"
echo ""
echo "   Or if connecting directly to the compute node:"
echo "   ssh -L $PORT:localhost:$PORT ${USER}@${NODE_NAME}"
echo ""
echo "2. Open in your browser:"
echo "   http://localhost:$PORT"
echo ""
echo "3. To stop TensorBoard, cancel this job:"
echo "   scancel $SLURM_JOB_ID"
echo ""
echo "=========================================="
echo ""

# Start TensorBoard
# Use --host 0.0.0.0 to allow access from other nodes
# Use --reload_interval=5 to reload data every 5 seconds
tensorboard --logdir "$LOG_DIR" --port "$PORT" --host 0.0.0.0 --reload_interval=5

# Capture exit code
TB_EXIT_CODE=$?

echo ""
echo "TensorBoard stopped at: $(date)"
if [ $TB_EXIT_CODE -eq 0 ]; then
    echo "TensorBoard exited normally."
else
    echo "TensorBoard exited with code $TB_EXIT_CODE"
fi
echo ""



