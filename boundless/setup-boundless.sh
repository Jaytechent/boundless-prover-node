#!/bin/bash

set -e

echo "=== Hallenjay Boundless Prover Setup Script ==="

# Step 0: Ask for user secrets to create an .env file
read -p "Paste your PRIVATE_KEY for env file: " PRIVATE_KEY
read -p "Paste your RPC_URL for env file: " RPC_URL

# Step 1: Install Docker (if not installed)
if ! command -v docker &> /dev/null; then
    echo ">>> Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
else
    echo ">>> Docker already installed. Skipping..."
fi

# Step 2: Install NVIDIA Docker
if ! command -v nvidia-docker &> /dev/null; then
    echo ">>> Installing NVIDIA Docker runtime..."
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    sudo apt update && sudo apt install -y nvidia-docker2
    sudo systemctl restart docker
else
    echo ">>> NVIDIA Docker already installed. Skipping..."
fi

# Step 3: Clone Boundless repo
if [ ! -d "boundless" ]; then
    echo ">>> Cloning Boundless repo..."
    git clone https://github.com/boundless-xyz/boundless
    cd boundless
    git checkout release-0.10
else
    echo ">>> Boundless repo already cloned."
    cd boundless
fi

# Step 4: Setup Boundless dependencies
echo ">>> Running Boundless setup script..."
sudo ./scripts/setup.sh

# Step 5: Install Rust and CLI tools
if ! command -v cargo &> /dev/null; then
    echo ">>> Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source $HOME/.cargo/env
else
    echo ">>> Rust already installed."
fi

echo ">>> Installing Bento CLI and Boundless CLI..."
cargo install --git https://github.com/risc0/risc0 bento-client --bin bento_cli || true
cargo install --locked boundless-cli || true

# Step 6: Setup .env.broker
echo ">>> Setting up environment..."
cp .env.broker-template .env.broker
echo "PRIVATE_KEY=\"$PRIVATE_KEY\"" >> .env.broker
echo "RPC_URL=\"$RPC_URL\"" >> .env.broker

echo ""
echo "🎉 Setup complete!"
echo "👉 Now run the next script: ./run-boundless.sh"
