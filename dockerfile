# We use a CUDA Devel image to ensure nvcc is available for compiling DeepSpeed kernels
FROM nvidia/cuda:13.1.0-devel-ubuntu24.04

# Set environment variables to non-interactive (this prevents some prompts)
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install System Dependencies
RUN apt-get update && apt-get install -y \
    git \
    git-lfs \
    curl \
    ffmpeg \
    libsndfile1 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Clone the Repository
WORKDIR /app
# Disable LFS to bypass "Quota Exceeded" error
ENV GIT_LFS_SKIP_SMUDGE=1
RUN git clone https://github.com/index-tts/index-tts.git .

# Initialize Git LFS and Environment
RUN git lfs install

# Install Python Dependencies via uv
# We use --system or creates a venv
# Since this is a container, we can let uv manage the venv,
# but we need to ensure the path is accessible.
ENV UV_PROJECT_ENVIRONMENT="/app/.venv"
RUN uv sync --all-extras

# Install CLI tools for model downloading
RUN uv tool install "huggingface-hub[cli,hf_xet]"
RUN uv tool install "modelscope"

# Add the virtual environment to PATH so we can run python/uv commands directly
ENV PATH="/app/.venv/bin:$PATH" \
    PATH="/root/.local/bin:$PATH"

# Expose the WebUI port
EXPOSE 7860

# Create a volume mount point for checkpoints so they persist between restarts
VOLUME /app/checkpoints

# Copy a startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set the entrypoint
ENTRYPOINT ["/start.sh"]

# Build:
# docker build -t indextts2 .

# Run:
# docker run --gpus all -it -p 7860:7860 -v $(pwd)/checkpoints:/app/checkpoints indextts2

# Run (Windows):
# docker run --gpus all -it -p 7860:7860 -v "%cd%\checkpoints":/app/checkpoints indextts2