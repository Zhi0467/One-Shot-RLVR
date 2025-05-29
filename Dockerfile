# Step 1: Use an NVIDIA NGC PyTorch base image for linux/amd64
FROM nvcr.io/nvidia/pytorch:24.03-py3

# Step 2: Install essential OS utilities for downloading Miniconda (if not already present)
# curl or wget. NGC images usually have one or both.
# Adding ca-certificates is good practice for HTTPS downloads.
RUN apt-get update && \
    apt-get install -y curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Step 3: Set the working directory
WORKDIR /app

# Step 4: Copy the entire repository content into the image
COPY . .

# Step 5: Download and Install Miniconda, then add to PATH
ENV CONDA_DIR=/opt/miniconda 
ENV PATH=$CONDA_DIR/bin:$PATH

RUN echo "Downloading and installing Miniconda..." && \
    curl -sSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh && \
    /bin/bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    # Ensure the conda command is available for the next steps by explicitly initializing for bash
    # and making sure the base conda environment is up-to-date.
    echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> ~/.bashrc && \
    conda init bash && \
    conda update -n base -c defaults conda -y && \
    pip install --upgrade pip setuptools # Upgrade pip in base conda env

# Step 6: Create the specific Conda environment for the project
# Now 'conda' command should be available.
RUN conda create -y -n rlvr_train python=3.10

# Step 7: Set the SHELL to run subsequent commands within the NEW Conda environment
# This activates 'rlvr_train' for subsequent RUN, CMD, ENTRYPOINT instructions.
SHELL ["conda", "run", "-n", "rlvr_train", "/bin/bash", "-c"]

# Sanity check: Verify Python and Pip are from the new environment
RUN echo "Python version in rlvr_train env:" && python --version
RUN echo "Pip version in rlvr_train env:" && pip --version

# Step 8: Install the 'verl' package (One-Shot-RLVR) in editable mode.
RUN pip install -e .

# Step 9: Install the specific PyTorch version with cu121 bindings, as per README.md.
# This will be installed into the 'rlvr_train' environment.
RUN pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu121

# Step 10: Install other Python dependencies from README.md
RUN pip install ray vllm==0.6.3
RUN pip install flash-attn --no-build-isolation
RUN pip install wandb matplotlib
RUN pip install huggingface_hub
RUN pip install xformers==0.0.27.post2 # From requirements_train.txt

# Step 11: Set common environment variables
ENV PYTHONUNBUFFERED=1
ENV TOKENIZERS_PARALLELISM=false
ENV VLLM_ATTENTION_BACKEND=XFORMERS

# Step 12: Make training scripts executable
RUN chmod +x scripts/train/*.sh

# Reset SHELL to default for CMD/ENTRYPOINT (optional, as conda run sets up the env)
# SHELL ["/bin/bash", "-c"]

# Example: Default command to activate environment and start bash
# CMD ["conda", "run", "-n", "rlvr_train", "bash"]