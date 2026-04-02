# NVIDIA CUDA & Container Toolkit Setup

Prepare an Ubuntu host to run GPU-accelerated Docker containers (required for the LLM stack).

## 1. Install CUDA Toolkit

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-6
```

## 2. Install NVIDIA Container Toolkit

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
```

## 3. Configure Docker runtime

```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# For rootless Docker (optional):
nvidia-ctk runtime configure --runtime=docker --config=$HOME/.config/docker/daemon.json
systemctl --user restart docker

sudo nvidia-ctk config --set nvidia-container-cli.no-cgroups --in-place
```

## 4. Install GPU drivers

```bash
sudo ubuntu-drivers install nvidia:555
```

## 5. Verify GPU access inside containers

```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-runtime-ubuntu22.04 nvidia-smi
```

The output should match `nvidia-smi` on the host.

### Troubleshooting: `Failed to initialize NVML: Unknown Error`

Edit the NVIDIA container runtime config:

```bash
sudo vim /etc/nvidia-container-runtime/config.toml
```

Set:

```toml
no-cgroups = false
```

Then restart Docker:

```bash
sudo systemctl restart docker
```

## References

- [CUDA Toolkit Downloads](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=24.04&target_type=deb_network)
- [NVIDIA Container Toolkit Install Guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
