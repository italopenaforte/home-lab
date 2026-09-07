# Backup e recuperação

## Backup

Conecte ou monte outro dispositivo e execute:

```bash
./scripts/backup.sh /mnt/backup
```

O script interrompe apenas os containers que estavam ativos, arquiva `.env` e
`CONFIG_ROOT`, e restaura o estado anterior. Guarde o arquivo fora do SSD do
servidor. A mídia não é copiada.

## Recuperação

Em um Ubuntu Server novo:

1. instale Docker;
2. clone este repositório;
3. pare a stack com `docker compose down`;
4. examine o backup com `tar -tzf ARQUIVO.tar.gz`;
5. restaure `.env` no repositório;
6. restaure o diretório `config` no `CONFIG_ROOT` indicado por `.env`;
7. confira proprietário e permissões;
8. execute `./scripts/deploy.sh`.

Se a mídia não tiver backup, Radarr e Sonarr conservarão o catálogo, mas os
arquivos precisarão ser baixados novamente.
