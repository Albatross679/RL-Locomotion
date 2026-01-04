#!/bin/bash

# TensorBoard script for SLURM training
# Usage: ./start_tensorboard_slurm.sh [logdir] [port]

# Set default values
LOG_DIR="${1:-./output}"
PORT="${2:-6006}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve absolute path for log directory
if [[ "$LOG_DIR" != /* ]]; then
    LOG_DIR="$SCRIPT_DIR/$LOG_DIR"
fi

echo "Starting TensorBoard for SLURM training..."
echo "Log directory: $LOG_DIR"
echo "Port: $PORT"
echo ""
echo "TensorBoard will read from the shared filesystem, so it can monitor"
echo "training that's running on compute nodes via SLURM."
echo ""
echo "To access from your local machine, use SSH port forwarding:"
echo "  ssh -L $PORT:localhost:$PORT your_username@remote_server"
echo ""
echo "Then open in your browser: http://localhost:$PORT"
echo ""
echo "Press Ctrl+C to stop TensorBoard"
echo ""

# Start TensorBoard
tensorboard --logdir "$LOG_DIR" --port "$PORT" --host 0.0.0.0 --reload_interval=5

