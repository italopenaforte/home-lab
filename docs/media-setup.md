# Configuração da stack de mídia

Substitua `IP_DO_SERVIDOR` pelo endereço reservado no roteador.

## 1. qBittorrent

Acesse `http://IP_DO_SERVIDOR:8080`, consulte a senha temporária nos logs e
troque-a imediatamente:

```bash
docker compose logs qbittorrent
```

Configure:

- pasta padrão: `/data/torrents`;
- pasta para downloads incompletos: `/data/torrents/incomplete`;
- categoria `movies`: `/data/torrents/movies`;
- categoria `tv`: `/data/torrents/tv`;
- uma meta de ratio ou tempo de seed compatível com o espaço disponível;
- pausa dos downloads quando restarem aproximadamente 50 GB no disco.

Não use `/downloads`: todos os serviços precisam enxergar os mesmos caminhos
dentro dos containers para que os hardlinks funcionem.

## 2. Radarr e Sonarr

Acesse Radarr em `http://IP_DO_SERVIDOR:7878` e Sonarr em
`http://IP_DO_SERVIDOR:8989`.

Crie estas bibliotecas:

- Radarr: `/data/library/movies`;
- Sonarr: `/data/library/tv`.

Nos dois serviços, adicione o cliente de download qBittorrent com hostname
`qbittorrent`, porta `8080` e as credenciais definidas anteriormente. Use a
categoria `movies` no Radarr e `tv` no Sonarr. Mantenha a opção de hardlinks
habilitada.

Para preservar espaço, comece com perfis 1080p e limites moderados de tamanho.

## 3. Prowlarr

Acesse `http://IP_DO_SERVIDOR:9696`, configure somente os indexadores necessários
e adicione as aplicações:

- Radarr: `http://radarr:7878`;
- Sonarr: `http://sonarr:8989`.

Use as API keys exibidas nas configurações de cada aplicação.

### FlareSolverr

Para um indexador que informe bloqueio por proteção anti-bot, abra
`Settings → Indexers → Indexer Proxies`, adicione `FlareSolverr` e configure:

```text
Name: FlareSolverr
Host: http://flaresolverr:8191
Request Max Timeout: 60
Tags: flaresolverr
```

Teste e salve. Depois edite apenas os indexadores que precisam do proxy e
adicione a mesma tag `flaresolverr`. Não deixe o campo de tags vazio, pois isso
aplicaria o proxy a todos os indexadores.

## 4. Jellyfin

Acesse `http://IP_DO_SERVIDOR:8096`, crie o usuário administrador e adicione:

- filmes: `/media/movies`;
- séries: `/media/tv`.

Em reprodução/transcoding, selecione Intel Quick Sync (QSV) e habilite apenas
os codecs suportados pelo hardware. Faça um teste reproduzindo um arquivo que
exija conversão e observe a GPU no host:

```bash
sudo intel_gpu_top
docker compose logs --tail=100 jellyfin
```

Sempre prefira clientes e formatos capazes de direct play. Isso reduz consumo,
calor e uso do SSD.

## 5. Verificação dos hardlinks

Após uma importação, compare o inode do arquivo baixado com o da biblioteca:

```bash
ls -li /srv/media/data/torrents/movies/ARQUIVO
ls -li /srv/media/data/library/movies/PASTA/ARQUIVO
```

Os números na primeira coluna devem ser iguais. Se forem diferentes, revise os
caminhos antes de continuar baixando conteúdo.
