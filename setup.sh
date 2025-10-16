#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: ./setup.sh [OPTIONS]

Options:
  --env-name NAME     Conda environment name (default: diffusion-evolution)
  --method METHOD     install method: conda or pip (default: conda if conda exists, else pip)
  --cuda VERSION      CUDA alias: cpu, cu118, cu121 (default: cu121)
  --help              show this help
Example:
  ./setup.sh --method pip --cuda cu121
  ./setup.sh --method conda --cuda cpu
EOF
}

# defaults
ENV_NAME="diffusion-evolution"
METHOD=""
CUDA="cu121"

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-name) ENV_NAME="$2"; shift 2;;
    --method) METHOD="$2"; shift 2;;
    --cuda) CUDA="$2"; shift 2;;
    --help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

# prefer conda if present and method not forced
if [[ -z "$METHOD" ]]; then
  if command -v conda &> /dev/null; then
    METHOD="conda"
  else
    METHOD="pip"
  fi
fi

echo "Install method: $METHOD"
echo "CUDA target: $CUDA"

install_pytorch_pip() {
  # Map CUDA target to PyTorch index url
  case "$CUDA" in
    cpu)
      INDEX_URL="https://download.pytorch.org/whl/cpu"
      ;;
    cu118)
      INDEX_URL="https://download.pytorch.org/whl/cu118"
      ;;
    cu121)
      INDEX_URL="https://download.pytorch.org/whl/cu121"
      ;;
    *)
      echo "Unknown CUDA target: $CUDA"; exit 1;;
  esac

  echo "Installing PyTorch (pip) from $INDEX_URL ..."
  python -m pip install --upgrade pip setuptools wheel
  python -m pip install "torch" "torchvision" "torchaudio" --index-url "${INDEX_URL}"
  echo "Installing remaining requirements..."
  python -m pip install -r requirements.txt
}

install_pytorch_conda() {
  # Using conda env creation with environment.yml, but we'll still ensure torch matches
  if ! command -v conda &> /dev/null; then
    echo "conda not found. Aborting."
    exit 1
  fi

  echo "Creating conda environment '${ENV_NAME}' with environment.yml..."
  conda env create -f environment.yml -n "${ENV_NAME}" || {
    echo "If the env already exists, try: conda env update -f environment.yml -n ${ENV_NAME}"
  }

  echo "Activating environment and ensuring torch is installed correctly..."
  if [[ "${CUDA}" == "cpu" ]]; then
    conda run -n "${ENV_NAME}" python -m pip install --upgrade pip setuptools wheel
    conda run -n "${ENV_NAME}" python -m pip install --index-url https://download.pytorch.org/whl/cpu "torch" "torchvision" "torchaudio"
  else
    case "$CUDA" in
      cu118)
        conda run -n "${ENV_NAME}" conda install -y pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia
        ;;
      cu121)
        conda run -n "${ENV_NAME}" conda install -y pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia
        ;;
      *)
        echo "Unknown CUDA target: $CUDA"; exit 1;;
    esac
    conda run -n "${ENV_NAME}" python -m pip install -r requirements.txt
  fi

  echo "Conda environment '${ENV_NAME}' created. To use it: conda activate ${ENV_NAME}"
}

if [[ "$METHOD" == "pip" ]]; then
  echo "Creating virtualenv in .venv..."
  python -m venv .venv
  # shellcheck disable=SC1090
  source .venv/bin/activate
  install_pytorch_pip
  echo "Done. Activate with: source .venv/bin/activate"
elif [[ "$METHOD" == "conda" ]]; then
  install_pytorch_conda
else
  echo "Unknown method: $METHOD"
  exit 1
fi

echo "Setup finished."
