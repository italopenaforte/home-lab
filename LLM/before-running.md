Preparar o ambiente Ubuntu para executar o Docker usando CUDA

CUDA Toolkit

```
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.debsudo
dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-6

```

NVIDIA Container Toolkit

```
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update

sudo apt-get install -y nvidia-container-toolkit

sudo nvidia-ctk runtime configure --runtime=docker

sudo systemctl restart docker

nvidia-ctk runtime configure --runtime=docker --config=$HOME/.config/docker/daemon.json

systemctl --user restart docker

sudo nvidia-ctk config --set nvidia-container-cli.no-cgroups --in-place
```

Instalando os drivers da placa de video
```
sudo ubuntu-drivers install nvidia:555
```

Pra testar se o por dentro do container tá conseguindo acessar a placa de video
```
docker run --rm --gpus all nvidia/cuda:11.8.0-runtime-ubuntu22.04 nvidia-smi
```

Se retornar as mesmas informações de quando rodar o nvidia-smi dentro do host então tá top

Se retornar esse erro ´´´Failed to initialize NVML: Unknown Error´´´ vai precisar alterar um parametro no ´´´config.toml´´´ do ´´´nvidia-container-runtime´´´

acesse o arquivo de configuração
´´´
sudo vim /etc/nvidia-container-runtime/config.toml
´´´

Modifique essa linha tornando ela false
```
no-cgroups = false
```
Salve a alteração e reinicie o docker
```
sudo systemctl restart docker
```


Referencias:

[Cuda Toolkit](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=24.04&target_type=deb_network)

[NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)