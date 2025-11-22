#!/usr/bin/env bash
set -euo pipefail

# Run the project setup using conda + cu121 by default in Codespaces
bash ../setup.sh --method conda --cuda cu121
