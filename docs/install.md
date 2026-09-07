# Instalação do host

## Instalação automatizada

Em uma instalação limpa do Ubuntu Server, execute como usuário normal:

```bash
./scripts/install.sh
```

O script:

- valida que o host executa Ubuntu;
- instala as ferramentas de diagnóstico da GPU Intel;
- instala Docker Engine pelo repositório oficial, se necessário;
- preserva uma instalação Docker que já esteja funcional;
- recusa remover automaticamente pacotes conflitantes;
- habilita o serviço Docker;
- adiciona o usuário atual ao grupo `docker`;
- prepara `/srv/media`;
- cria `.env` e preenche os IDs do usuário e da GPU.

Ele não inicia os containers. Após a instalação do Docker, encerre a sessão SSH,
entre novamente e execute:

```bash
./scripts/deploy.sh
```

As etapas abaixo documentam o que o instalador faz e servem para diagnóstico ou
instalação manual.

## 1. Ubuntu Server

Instale Ubuntu Server 24.04 LTS diretamente no SSD, sem ambiente gráfico.
Durante a instalação, habilite OpenSSH e use o filesystem ext4. Para permitir
que o servidor volte sozinho após uma queda de energia, habilite também a opção
de restauração de energia no firmware do mini PC.

Atualize o sistema:

```bash
sudo apt update
sudo apt full-upgrade
sudo reboot
```

## 2. Docker

Instale Docker Engine e o plugin Compose seguindo a documentação oficial para
Ubuntu: <https://docs.docker.com/engine/install/ubuntu/>.

Adicione o usuário administrador ao grupo Docker e entre novamente na sessão:

```bash
sudo usermod -aG docker "$USER"
```

Confirme a instalação:

```bash
docker version
docker compose version
```

Pertencer ao grupo `docker` equivale a ter privilégios administrativos no host.
Não conceda esse acesso a usuários não confiáveis.

## 3. Aceleração Intel

Instale as ferramentas de diagnóstico:

```bash
sudo apt install vainfo intel-gpu-tools
ls -l /dev/dri
getent group render
getent group video
```

O dispositivo `/dev/dri/renderD128` deve existir. Anote os números dos grupos
`render` e `video`; eles serão usados em `.env`.

## 4. Diretórios

Crie a raiz persistente e entregue-a ao usuário que executará Docker:

```bash
sudo install -d -o "$(id -u)" -g "$(id -g)" /srv/media
mkdir -p /srv/media/config /srv/media/data
```

Clone o repositório, crie `.env` e ajuste `PUID`, `PGID`, `RENDER_GID` e
`VIDEO_GID` com os valores do host:

```bash
cp .env.example .env
nano .env
./scripts/deploy.sh
```

## 5. Rede

Reserve um endereço IP para o mini PC no DHCP do roteador. Não encaminhe as
portas web no roteador. Para acesso remoto, prefira uma VPN como Tailscale em
vez de expor os serviços diretamente.

Se UFW estiver ativo, libere SSH e as portas web somente para a sub-rede local.
O número da sub-rede depende da configuração do roteador.
