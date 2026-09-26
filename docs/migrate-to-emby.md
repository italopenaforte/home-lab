# Migrar do Jellyfin para o Emby

A biblioteca continua em `DATA_ROOT/library`, montada em `/media` somente para
leitura. O Emby começa com configuração própria em `CONFIG_ROOT/emby`.
As pastas `CONFIG_ROOT/jellyfin` e `CONFIG_ROOT/jellyfin-cache` são preservadas.
Não copie o banco do Jellyfin para o Emby: este procedimento não transfere
usuários, senhas, plugins, configurações ou histórico de reprodução.

## 1. Backup antes da troca

No servidor, **ainda com a versão antiga do Compose**, execute:

```bash
./scripts/backup.sh /mnt/backup
```

Esse passo precisa ocorrer antes de atualizar o repositório, para que o script
consiga parar também o Jellyfin durante o backup. Escolha um destino montado
fora de `CONFIG_ROOT`. Guarde também a revisão antiga do repositório para retorno.

## 2. Trocar os containers

Atualize os arquivos do repositório no servidor. No `.env`, renomeie
`JELLYFIN_PORT` para `EMBY_PORT`, mantendo o valor existente. O Compose também
aceita `JELLYFIN_PORT` como fallback, para preservar portas personalizadas em
instalações antigas; `EMBY_PORT` tem prioridade.

Valide a configuração e baixe a imagem antes de interromper o serviço:

```bash
docker compose config --quiet
docker compose pull emby
docker stop jellyfin
./scripts/deploy.sh
```

Não use `--add-ons` nesta migração: essa opção só instala Bazarr e Seerr.
O container antigo fica parado, disponível para retorno. Não execute
`--remove-orphans` enquanto precisar dele. O aviso de container órfão é esperado.
O deploy cria a pasta do Emby, inicia o serviço e atualiza o atalho do Homepage.

## 3. Configurar e validar

Abra `http://IP_DO_SERVIDOR:8096` (ou a porta configurada), crie o administrador
e adicione `/media/movies` e `/media/tv`. Aguarde a varredura da biblioteca.
Recrie os demais usuários e siga a seção Emby de [media-setup.md](media-setup.md)
para configurar reprodução e aceleração por GPU.

No Seerr, a conexão nova é do tipo **Emby**, no endereço `http://emby:8096`.
A troca do Compose não altera a configuração persistente do Seerr. Confira se
a versão instalada oferece migração de servidor antes de trocar a conexão;
não apague `CONFIG_ROOT/seerr` nem edite seu banco para forçar a troca.
Se não houver essa opção, mantenha o backup e trate a migração do Seerr
separadamente. A funcionalidade de migração é descrita nesta
[discussão do projeto](https://github.com/seerr-team/seerr/discussions/2792).
Após conectar, autentique com o administrador do Emby, selecione as bibliotecas,
sincronize e confira usuários e pedidos existentes.

Valide:

- reprodução de um filme e episódio, incluindo legendas externas;
- direct play e, se usar Premiere, transcodificação por GPU;
- atalho do Homepage e sincronização das bibliotecas no Seerr;
- um pedido no Seerr chegando ao Radarr/Sonarr.

```bash
docker compose ps
docker compose logs --tail=100 emby
```

## Retorno ao Jellyfin

Se a inicialização ou reprodução falhar, libere a porta e reinicie o container
antigo, que conserva suas montagens e configuração:

```bash
docker compose stop emby
docker start jellyfin
```

Restaure os arquivos da revisão anterior e o `.env` antigo para os próximos
deploys e para recuperar o atalho do Homepage. Se o Seerr já tiver sido
reconfigurado, pare-o e restaure sua configuração do backup antes de reiniciar.
Mantenha os dados antigos até concluir todas as verificações.
