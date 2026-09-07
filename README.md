# Media Server

Servidor de mídia doméstico enxuto para um mini PC com Ubuntu Server. A stack
baixa torrents, organiza filmes e séries e disponibiliza a biblioteca pelo
Jellyfin.

## Arquitetura

```text
qBittorrent <── Radarr / Sonarr <── Prowlarr
     │               │
     └──── /data ────┴────────────> Jellyfin
```

Serviços incluídos:

| Serviço | Função | Porta padrão |
| --- | --- | ---: |
| qBittorrent | Download e seed | `8080` |
| Prowlarr | Gerenciamento de indexadores | `9696` |
| Radarr | Organização de filmes | `7878` |
| Sonarr | Organização de séries | `8989` |
| Jellyfin | Reprodução da biblioteca | `8096` |

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

Depois do primeiro acesso, siga [docs/media-setup.md](docs/media-setup.md) para
ligar qBittorrent, Prowlarr, Radarr, Sonarr e Jellyfin.

## Layout de dados

```text
/srv/media/
├── config/
│   ├── jellyfin/
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
podem usar hardlinks e um arquivo em seed não consome o dobro do espaço.

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
