#!/bin/bash
set -e

echo "Starting IndexTTS2 Container..."

# Check if checkpoints directory is empty
if [ -z "$(ls -A checkpoints)" ]; then
    echo "⬇Checkpoints directory appears empty. Downloading models..."
    
    # Try to pull LFS files, but don't crash if it fails due to quota
    echo "Attempting to pull LFS files (examples)..."
    git lfs pull || echo "LFS Quota exceeded on remote. Skipping example audio files."

    # Download via huggingface-cli
    if [ ! -z "$HF_ENDPOINT" ]; then
        echo "Using HF Mirror: $HF_ENDPOINT"
    fi

    echo "Downloading IndexTTS-2 models... this may take a while."
    # Use 'uv tool run' to ensure the command is found regardless of PATH
    uv tool run --from "huggingface-hub[cli,hf_xet]" hf download IndexTeam/IndexTTS-2 --local-dir checkpoints
else
    echo "Checkpoints detected. Skipping download."
fi

# Run the WebUI
echo "Launching WebUI..."

# Using 'uv run' ensures the environment is active
exec uv run webui.py --host 0.0.0.0 --fp16 --cuda_kernel
