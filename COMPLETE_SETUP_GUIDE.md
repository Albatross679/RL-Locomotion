# Complete Setup Guide - RL Locomotion Project

**Date**: December 26, 2024  
**System**: Linux Server (No Sudo Access)  
**Location**: `/home/wen.679/RL_locomotion`

This document provides a complete record of the setup process for the RL Locomotion project, including all dependencies, configurations, and installations.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Conda Environment Setup](#conda-environment-setup)
3. [C++ Dependencies](#c-dependencies)
4. [CMake Configuration](#cmake-configuration)
5. [Python Packages](#python-packages)
6. [Core Repositories](#core-repositories)
7. [Git Configuration](#git-configuration)
8. [Environment Variables](#environment-variables)
9. [Verification](#verification)
10. [Troubleshooting](#troubleshooting)

---

## System Overview

### Operating System
- **OS**: Linux (Red Hat Enterprise Linux 8.5)
- **Kernel**: 4.18.0-553.89.1.el8_10.x86_64
- **Shell**: /bin/bash

### Python Environment
- **Python Version**: 3.12.12
- **Conda Environment**: `rl-locomotion`
- **Conda Environment Path**: `/home/wen.679/miniconda3/envs/rl-locomotion`
- **Total Packages Installed**: 234 packages

### Build Tools
- **CMake**: 3.31.1 (conda-forge)
- **GCC/G++**: 8.5.0 (system)
- **Ninja**: 1.13.2 (conda-forge)

---

## Conda Environment Setup

### Environment Creation

The `rl-locomotion` conda environment was created with Python 3.12:

```bash
conda create -n rl-locomotion python=3.12 -y
conda activate rl-locomotion
```

### C++ Dependencies via Conda

All C++ dependencies were installed via conda-forge (no sudo required):

```bash
conda install -c conda-forge \
    cmake \
    ninja \
    eigen \
    llvm \
    boost-cpp \
    libxml2 \
    libxslt \
    freetype \
    jpeg \
    gmp \
    mkl \
    mkl-devel \
    symengine \
    fcl \
    -y
```

**Note**: `boost-cpp` is required for ALF's fast parallel environment extension (`penv`), which is essential for multi-GPU training. See the ALF section and Troubleshooting section for Boost configuration details.

### Installed C++ Packages

| Package | Version | Source |
|---------|---------|--------|
| cmake | 3.31.1 | conda-forge |
| ninja | 1.13.2 | conda-forge |
| eigen | 3.4.0 | conda-forge |
| llvm | 19.1.7 | conda-forge |
| boost-cpp | 1.85.0 | conda-forge |
| mkl | 2025.0.0 | conda-forge |
| mkl-devel | 2025.0.0 | conda-forge |
| symengine | Latest | conda-forge |
| fcl | Latest | conda-forge |

---

## C++ Dependencies

### Intel MKL (Math Kernel Library)

**Installation Method**: Conda (no sudo required)

```bash
conda install -c conda-forge mkl mkl-devel -y
export MKL_DIR=$CONDA_PREFIX
```

**Location**: `/home/wen.679/miniconda3/envs/rl-locomotion`

### Eigen3

**Installation Method**: Conda

```bash
conda install -c conda-forge eigen -y
```

**Version**: 3.4.0  
**Location**: Conda environment

### SymEngine

**Installation Method**: Conda

```bash
conda install -c conda-forge symengine -y
```

**Purpose**: Symbolic computation library

### FCL (Flexible Collision Library)

**Installation Method**: Conda

```bash
conda install -c conda-forge fcl -y
```

**Purpose**: Collision detection

### Boost

**Installation Method**: Conda

```bash
conda install -c conda-forge boost-cpp -y
```

**Version**: 1.85.0

---

## CMake Configuration

### CMake Installation

- **Version**: 3.31.1
- **Source**: conda-forge
- **Location**: `/home/wen.679/miniconda3/envs/rl-locomotion/bin/cmake`
- **Requirement**: >= 3.11 ✅ (Meets requirement)

### CMake Environment Variables

```bash
export CMAKE_PREFIX_PATH=$CONDA_PREFIX:$CMAKE_PREFIX_PATH
export MKL_DIR=$CONDA_PREFIX
```

### Building dismech-rods

```bash
cd dismech-rods
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=$CONDA_PREFIX ..
make -j$(nproc)
cd .. && pip install -e .
```

**Build Artifacts**:
- `libcommon_sources.a` (13.2 MB)
- `py_dismech.cpython-312-x86_64-linux-gnu.so` (1.3 MB)
- CMake cache and build files

---

## Python Packages

### Core Deep Learning Framework

#### PyTorch
- **Version**: 2.6.0+cu124
- **Installation**:
  ```bash
  pip install torch==2.6.0 torchvision \
      --index-url https://download.pytorch.org/whl/cu124
  ```
- **CUDA Support**: CUDA 12.4
- **Components**: torch, torchvision, torchtext

### Scientific Computing

| Package | Version | Purpose |
|---------|---------|---------|
| numpy | 1.26.4 | Numerical computing |
| scipy | 1.16.3 | Scientific computing |
| matplotlib | 3.10.8 | Plotting and visualization |
| sympy | 1.14.0 | Symbolic mathematics |

### Reinforcement Learning

| Package | Version | Purpose |
|---------|---------|---------|
| gym | 0.15.4 | RL environments |
| gymnasium | 1.2.3 | Modern RL environments |
| gym3 | 0.3.3 | Vectorized RL environments |

### Visualization

| Package | Version | Purpose |
|---------|---------|---------|
| pyvista | 0.46.4 | 3D visualization |
| plotly | 6.5.0 | Interactive plots |

### Physics Simulators

| Package | Version | Purpose |
|---------|---------|---------|
| pyelastica | 0.2.4 | Alternative soft body simulator |
| py_dismech | 0.1 | DisMech Python bindings |

### Project-Specific Packages

#### ALF (Agent Learning Framework)
- **Version**: 0.1.0
- **Source**: https://github.com/HorizonRobotics/alf
- **Installation**:
  ```bash
  git clone --depth=1 https://github.com/HorizonRobotics/alf.git alf
  cd alf && pip install -e . && pip install pyvista
  cd ..
  ```
- **Location**: `/home/wen.679/RL_locomotion/alf`
- **Boost Requirement**: ALF requires Boost C++ libraries for its fast parallel environment extension (`penv`), which is essential for multi-GPU training. Boost is installed via `boost-cpp` in the conda environment (see Step 1).
- **Boost Verification**:
  ```bash
  # Verify Boost headers are available
  ls $CONDA_PREFIX/include/boost/interprocess/ipc/message_queue.hpp
  
  # If missing, install:
  conda install -c conda-forge boost-cpp -y
  ```
- **Environment Variables for Boost** (required for compilation):
  ```bash
  export CPLUS_INCLUDE_PATH="${CONDA_PREFIX}/include:${CPLUS_INCLUDE_PATH}"
  export LIBRARY_PATH="${CONDA_PREFIX}/lib:${LIBRARY_PATH}"
  export LD_LIBRARY_PATH="${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH}"
  ```

#### dismech-python
- **Version**: 0.1.0
- **Source**: https://github.com/Albatross679/dismech-python
- **Installation**:
  ```bash
  git clone https://github.com/Albatross679/dismech-python.git dismech-python
  cd dismech-python
  # Modified pyproject.toml: requires-python = ">=3.12" (was >=3.13)
  pip install -e .
  pip install ipython  # Additional dependency
  cd ..
  ```
- **Location**: `/home/wen.679/RL_locomotion/dismech-python`
- **Dependencies**: matplotlib, numba, plotly, scipy, sympy, ipython

### Additional Dependencies from dismech-rl

Installed from `dismech-rl/docker/requirements.txt`:

```bash
pip install -r dismech-rl/docker/requirements.txt
```

**Key packages**:
- absl-py==2.2.2
- atari_py==0.2.9
- box2d-py==2.3.8
- gin-config (from git)
- h5py==3.13.0
- opencv-python==4.11.0.86
- tensorboard==2.19.0
- pybullet==2.5.0
- And many more...

---

## Core Repositories

### 1. dismech-rods

**Repository**: https://github.com/StructuresComp/dismech-rods  
**Location**: `/home/wen.679/RL_locomotion/dismech-rods`  
**Status**: Cloned and built

**Installation Steps**:
```bash
git clone --depth=1 https://github.com/StructuresComp/dismech-rods.git dismech-rods
cd dismech-rods
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=$CONDA_PREFIX ..
make -j$(nproc)
cd .. && pip install -e .
cd ..
```

**Build Output**:
- C++ library: `libcommon_sources.a`
- Python bindings: `py_dismech.cpython-312-x86_64-linux-gnu.so`
- Python package: `py_dismech` (installed in editable mode)

### 2. alf

**Repository**: https://github.com/HorizonRobotics/alf  
**Location**: `/home/wen.679/RL_locomotion/alf`  
**Status**: Cloned and installed

**Installation Steps**:
```bash
git clone --depth=1 https://github.com/HorizonRobotics/alf.git alf
cd alf && pip install -e . && pip install pyvista
cd ..
```

**Purpose**: Agent Learning Framework for RL research

### 3. dismech-python

**Repository**: https://github.com/Albatross679/dismech-python  
**Location**: `/home/wen.679/RL_locomotion/dismech-python`  
**Status**: Cloned and installed (editable mode)

**Installation Steps**:
```bash
git clone https://github.com/Albatross679/dismech-python.git dismech-python
cd dismech-python
# Modified pyproject.toml: requires-python = ">=3.12"
pip install -e .
pip install ipython  # Missing dependency
cd ..
```

**Modifications**:
- Changed `requires-python = ">=3.13"` to `">=3.12"` in `pyproject.toml`
- Installed `ipython` as additional dependency

**Dependencies**:
- matplotlib>=3.10.3
- numba>=0.61.2
- plotly>=6.2.0
- scipy>=1.16.1
- sympy>=1.14.0

### 4. dismech-rl

**Repository**: https://github.com/Albatross679/dismech-rl  
**Location**: `/home/wen.679/RL_locomotion/dismech-rl`  
**Status**: Cloned (ready to use)

**Installation Steps**:
```bash
git clone https://github.com/Albatross679/dismech-rl.git dismech-rl
pip install -r dismech-rl/docker/requirements.txt
```

**Contents**:
- Configuration files: `confs/` (8 config files)
- Environments: `environments/`
- Docker setup: `docker/`
- Requirements: `docker/requirements.txt`

**Configuration Files**:
- `follow_conf.py` - Target following task
- `ik_conf.py` - Inverse kinematics 4D
- `obs_2d_conf.py` - 2D obstacle reaching
- `obs_3d_conf.py` - 3D obstacle reaching
- `common_sac_training_conf.py` - SAC training config
- `common_ppo_training_conf.py` - PPO training config
- `rl_alg_constructor.py` - RL algorithm constructor

---

## Git Configuration

### Repository Setup

**Main Repository**: `/home/wen.679/RL_locomotion`  
**Remote**: `git@github.com:Albatross679/RL-Locomotion.git`  
**Branch**: `main`

### Git User Configuration

```bash
git config user.name "Albatross679"
git config user.email "qifan_wen@outlook.com"
```

### SSH Key Setup

**Key Type**: ED25519  
**Key Location**: `~/.ssh/id_ed25519`  
**Public Key Location**: `~/.ssh/id_ed25519.pub`  
**Key Fingerprint**: `SHA256:0Iirez3IdinK59JVhGGTm/Tob+LnjW2oPrxYkYuHVTo`

**Public Key**:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICVU3zEPx88rcN6AB++Olxqmui+Y4wxRLYv9omyUHoeq qifan_wen@outlook.com
```

**GitHub**: Added to https://github.com/settings/keys

### Repository Initialization

```bash
git init
git branch -m main
git remote add origin git@github.com:Albatross679/RL-Locomotion.git
```

### Initial Commit

```bash
git add .gitignore
git commit -m "Initial commit: Add .gitignore"
```

**Commit Hash**: `3309345`

### .gitignore

Created comprehensive `.gitignore` excluding:
- Build artifacts (`build/`, `*.so`, etc.)
- Python cache (`__pycache__/`, `*.pyc`)
- Conda environments
- Output directories
- Large data files

---

## Environment Variables

### Required Environment Variables

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Conda environment
export CONDA_PREFIX=/home/wen.679/miniconda3/envs/rl-locomotion

# MKL Configuration
export MKL_DIR=$CONDA_PREFIX

# CMake Configuration
export CMAKE_PREFIX_PATH=$CONDA_PREFIX:$CMAKE_PREFIX_PATH

# Python Path
export PYTHONPATH=$PYTHONPATH:/home/wen.679/RL_locomotion/dismech-rods:/home/wen.679/RL_locomotion/alf

# OpenMP Threading
export OMP_NUM_THREADS=1

# CUDA Configuration (if using GPU)
export CUBLAS_WORKSPACE_CONFIG=:4096:8

# Graphics/EGL (for headless rendering if needed)
export PYOPENGL_PLATFORM=egl
```

### Library Paths

```bash
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$CONDA_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH
```

---

## Verification

### Verify Installation

Run the verification script:

```bash
conda activate rl-locomotion
python verify_installation.py
```

### Manual Verification

```bash
# Test Python packages
python -c "import py_dismech; print('✓ py_dismech')"
python -c "import alf; print('✓ alf')"
python -c "import dismech; print('✓ dismech')"
python -c "import torch; print('✓ PyTorch', torch.__version__)"
python -c "import numpy; print('✓ NumPy', numpy.__version__)"

# Test CMake
cmake --version

# Test Git
git remote -v
ssh -T git@github.com
```

### Expected Results

All components should import successfully:
- ✅ py_dismech
- ✅ alf
- ✅ dismech (dismech-python)
- ✅ torch, numpy, scipy, matplotlib
- ✅ gym, pyvista, pyelastica
- ✅ CMake 3.31.1
- ✅ Git remote configured
- ✅ SSH connection to GitHub working

---

## Installation Summary

### What Was Installed

1. **Conda Environment**: `rl-locomotion` with Python 3.12.12
2. **C++ Dependencies**: CMake, Eigen, MKL, SymEngine, FCL, Boost, LLVM
3. **Python Packages**: 234 total packages including:
   - PyTorch 2.6.0+cu124
   - ALF framework
   - dismech-python
   - All RL dependencies
4. **Repositories**: 4 repositories cloned and configured
5. **Build Tools**: CMake 3.31.1, GCC 8.5.0, Ninja 1.13.2
6. **Git**: Repository initialized with SSH connection to GitHub

### Installation Method

**Approach**: Conda-based (no Docker, no sudo required)

- All dependencies installed via conda or pip
- Everything in user's home directory
- No system-wide installations
- No Docker containers

### Key Modifications

1. **dismech-python**: Changed Python requirement from >=3.13 to >=3.12
2. **dismech-python**: Added ipython dependency
3. **Environment**: Used existing conda environment instead of creating new

---

## Troubleshooting

### Common Issues

#### 1. Import Errors

**Problem**: `ModuleNotFoundError` for py_dismech, alf, or dismech

**Solution**:
```bash
conda activate rl-locomotion
export PYTHONPATH=$PYTHONPATH:$(pwd)/dismech-rods:$(pwd)/alf
```

#### 2. CMake Cannot Find Dependencies

**Problem**: CMake errors about missing Eigen, MKL, etc.

**Solution**:
```bash
export CMAKE_PREFIX_PATH=$CONDA_PREFIX:$CMAKE_PREFIX_PATH
export MKL_DIR=$CONDA_PREFIX
```

#### 3. SSH Connection to GitHub Fails

**Problem**: `Permission denied` or `Host key verification failed`

**Solution**:
```bash
# Add GitHub to known_hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Verify key is added to GitHub
ssh -T git@github.com
```

#### 4. Build Failures

**Problem**: dismech-rods build fails

**Solution**:
```bash
# Clean build
cd dismech-rods
rm -rf build
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=$CONDA_PREFIX ..
make -j$(nproc)
```

#### 5. Boost Headers Not Found During ALF Extension Compilation

**Problem**: `fatal error: boost/interprocess/ipc/message_queue.hpp: No such file or directory` when running ALF training

**Solution**:
```bash
# 1. Verify Boost is installed in conda environment
conda activate rl-locomotion
ls $CONDA_PREFIX/include/boost/interprocess/ipc/message_queue.hpp

# 2. If missing, install Boost
conda install -c conda-forge boost-cpp -y

# 3. Set environment variables before running training
export CPLUS_INCLUDE_PATH="${CONDA_PREFIX}/include:${CPLUS_INCLUDE_PATH}"
export LIBRARY_PATH="${CONDA_PREFIX}/lib:${LIBRARY_PATH}"
export LD_LIBRARY_PATH="${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH}"

# 4. For SLURM jobs, add these exports to your SLURM script
```

**Note**: This error occurs when ALF tries to compile the `penv` (parallel environment) C++ extension, which is required for fast parallel environment execution in multi-GPU training. The Boost library is already included in the conda installation (Step 1), but environment variables may need to be configured.

### Verification Commands

```bash
# Check conda environment
conda activate rl-locomotion
conda list | grep -E "cmake|eigen|mkl|torch|alf"

# Check Python packages
pip list | grep -E "dismech|alf|torch"

# Check git
git remote -v
git status

# Check CMake
cmake --version
```

---

## Quick Reference

### Activate Environment
```bash
conda activate rl-locomotion
```

### Update Environment Variables
```bash
source ~/.bashrc  # or ~/.zshrc
```

### Run Training
```bash
conda activate rl-locomotion
export OMP_NUM_THREADS=1
python -m alf.bin.train \
    --conf dismech-rl/confs/obs_3d_conf.py \
    --root_dir ./output \
    --conf_param "sim_framework='dismech'"
```

### Push to GitHub
```bash
git add .
git commit -m "Your message"
git push -u origin main
```

---

## File Structure

```
/home/wen.679/RL_locomotion/
├── alf/                    # ALF framework
├── dismech-rods/          # DisMech C++ library
│   ├── build/             # Build artifacts
│   └── py_dismech/        # Python bindings
├── dismech-python/        # DisMech Python wrapper
├── dismech-rl/            # RL configurations
│   ├── confs/             # Training configurations
│   └── environments/     # RL environments
├── .git/                  # Git repository
├── .gitignore            # Git ignore rules
├── COMPLETE_SETUP_GUIDE.md  # This document
├── GIT_SETUP_RECORD.md    # Git setup details
├── MISSING_COMPONENTS_REPORT.md  # Component status
├── DOCKER_VS_CONDA_COMPARISON.md # Setup comparison
└── verify_installation.py # Verification script
```

---

## Conclusion

This setup provides a complete RL Locomotion development environment without requiring sudo access or Docker. All dependencies are managed through conda and pip, with everything installed in the user's home directory.

**Total Setup Time**: ~30-45 minutes (with conda)  
**Total Packages**: 234 packages  
**Repositories**: 4 cloned and configured  
**Status**: ✅ All components verified and working

---

**Last Updated**: December 26, 2024  
**Maintained By**: Albatross679

