# Setup instructions for diffusion-evolution

This file explains how to set up the Python / PyTorch environment to run experiments locally, on GitHub Codespaces, or via conda/pip.

Quick choices:
- Local conda preferred (GPU support via pytorch-cuda/pytorch channel)
- Local pip + venv works well (use the included setup.sh to fetch an appropriate torch wheel)
- Codespaces: use the included .devcontainer which runs the setup script on post-create

Defaults in these files target CUDA cu121. If you need CPU-only, pass `--cuda cpu` to the setup script or edit `environment.yml`.

1) Using conda (recommended when using GPU)
- Create from template:
  - Edit `environment.yml` to change python version or remove CUDA-specific steps.
  - Run:
    ```bash
    conda env create -f environment.yml -n diffusion-evolution
    conda activate diffusion-evolution
    ```

- Or use the helper script:
    ```bash
    ./setup.sh --method conda --cuda cu121
    ```

2) Using pip + venv

```bash
./setup.sh --method pip --cuda cpu
# or for CUDA
./setup.sh --method pip --cuda cu121
source .venv/bin/activate
```

3) Verifying PyTorch and GPU

```bash
python -c "import torch; print('torch', torch.__version__, 'cuda available', torch.cuda.is_available()); print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else '')"
```

4) Codespaces / devcontainer
- The provided `.devcontainer/` runs the setup script after the container is created. It uses a Miniconda-based image so conda installs are available.

5) CI notes
- The included GitHub Actions workflow runs on CPU and performs a smoke test installing the CPU PyTorch wheel and the requirements.

If you'd like, I can adjust the devcontainer to pre-install GPU-capable CUDA drivers or pin exact package versions.
