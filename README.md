# Media Server

Servidor de mídia doméstico enxuto para um mini PC com Ubuntu Server. A stack
recebe pedidos de filmes e séries, baixa torrents, organiza a biblioteca,
busca legendas e disponibiliza o conteúdo pelo Emby.

## Arquitetura

```text
Seerr ──> Radarr / Sonarr <── Prowlarr
                │
                ├──> qBittorrent
                └──> /data/library ──> Emby
Bazarr <── Radarr / Sonarr
   └────> legendas em /data/library
```

Serviços incluídos:

| Serviço | Função | Porta padrão |
| --- | --- | ---: |
| qBittorrent | Download e seed | `8080` |
| Prowlarr | Gerenciamento de indexadores | `9696` |
| Radarr | Organização de filmes | `7878` |
| Sonarr | Organização de séries | `8989` |
| Bazarr | Busca automática de legendas | `6767` |
| Emby | Reprodução da biblioteca | `8096` |
| Seerr | Pedidos de filmes e séries | `5055` |
| Homepage | Atalhos para todas as interfaces | `3000` |

Não há proxy reverso nem portas publicadas na internet: a stack foi projetada
para uso na rede local.

## Host recomendado

- Ubuntu Server 24.04 LTS, sem interface gráfica
- Docker Engine e Docker Compose
- 16 GB de RAM
- GPU integrada Intel disponível em `/dev/dri`
- SSD interno para sistema, configurações, downloads e biblioteca

Veja [docs/install.md](docs/install.md) para preparar o host.

## Início rápido

```bash
./scripts/install.sh
# Entre novamente na sessão para ativar o grupo docker
./scripts/deploy.sh
./scripts/status.sh
```

A página inicial fica em `http://HOMEPAGE_SERVER_HOST:3000`. Ajuste
`HOMEPAGE_SERVER_HOST` no `.env` para o IP reservado ou hostname do servidor.

Depois do primeiro acesso, siga [docs/media-setup.md](docs/media-setup.md) para
ligar qBittorrent, Prowlarr, Radarr, Sonarr, Emby, Seerr e Bazarr.

Para uma instalação que ainda usa Jellyfin, siga primeiro
[docs/migrate-to-emby.md](docs/migrate-to-emby.md). O Emby usa configuração
separada e reaproveita os arquivos da biblioteca; usuários e histórico não
são transferidos automaticamente.

### Adição a uma stack já em execução

Se os serviços antigos já estão funcionando no servidor, execute no diretório
deste repositório:

```bash
./scripts/deploy.sh --add-ons
```

O script cria os diretórios de configuração, sobe Bazarr e Seerr e recria
apenas o Homepage para carregar os novos atalhos. Os outros serviços continuam
com seus containers e imagens atuais. Antes, confira se as portas `5055` e
`6767` estão livres. Se sua instalação usa valores diferentes no `.env`, o
Compose respeita esses valores.

## Layout de dados

```text
/srv/media/
├── config/
│   ├── emby/
│   ├── seerr/
│   ├── bazarr/
│   ├── prowlarr/
│   ├── qbittorrent/
│   ├── radarr/
│   └── sonarr/
└── data/
    ├── torrents/
    │   ├── movies/
    │   └── tv/
    └── library/
        ├── movies/
        └── tv/
```

qBittorrent, Radarr e Sonarr recebem a mesma montagem `/data`. Assim, imports
podem usar hardlinks e um arquivo em seed não consome o dobro do espaço. Bazarr
acessa a biblioteca pelos mesmos caminhos `/data/library` para salvar legendas.

## Operação

```bash
./scripts/install.sh                    # prepara um Ubuntu Server novo
./scripts/deploy.sh                     # cria/atualiza a stack
./scripts/status.sh                     # containers, armazenamento e GPU
./scripts/update.sh                     # baixa imagens e recria containers
./scripts/backup.sh /mnt/backup         # salva configurações, não a mídia
docker compose down                     # para e remove somente esta stack
```

As imagens usam o canal estável publicado por cada projeto e só são atualizadas
quando `scripts/update.sh` é executado. Não há atualização automática.

## Capacidade

Com apenas 512 GB, mantenha pelo menos 50 GB livres, prefira conteúdo 1080p e
configure limites de seed e retenção no qBittorrent. O script de status avisa
quando o filesystem de dados ultrapassa 90% de utilização.

## Recuperação

O backup contém `.env` e todos os diretórios de configuração. A mídia não é
incluída. Consulte [docs/recovery.md](docs/recovery.md).
