# Migrar do Jellyfin para o Emby

A biblioteca continua em `DATA_ROOT/library`, montada em `/media` somente para
leitura. O Emby começa com configuração própria em `CONFIG_ROOT/emby`.
As pastas `CONFIG_ROOT/jellyfin` e `CONFIG_ROOT/jellyfin-cache` são preservadas.
Não copie o banco do Jellyfin para o Emby: este procedimento não transfere
usuários, senhas, plugins, configurações ou histórico de reprodução.

## 1. Executar a troca

No servidor Ubuntu, atualize este repositório e mantenha o `.env` da instalação
atual. Execute:

```bash
./scripts/deploy.sh
```

O deploy detecta o container `jellyfin`, verifica o projeto e o diretório de
configuração, baixa as imagens do Emby e Homepage, para e **remove o container
Jellyfin**, e sobe a stack com o Emby e o Homepage atualizado. Ele espera a
interface do Emby responder antes de informar sucesso.

Não há backup nem retorno automático ao Jellyfin. Se o Emby falhar, o script
encerra com erro; consulte os logs, corrija a causa e rode o deploy novamente.
Os diretórios antigos `CONFIG_ROOT/jellyfin` e `CONFIG_ROOT/jellyfin-cache`
permanecem no disco, mas não são usados pelo Emby. A biblioteca é preservada.

O `.env` antigo funciona: `JELLYFIN_PORT` continua aceito como fallback para
`EMBY_PORT`. Se definir ambos, `EMBY_PORT` tem prioridade. Não use `--add-ons`
para essa troca, pois essa opção só instala Bazarr e Seerr.

## 2. Configurar e validar

Abra `http://IP_DO_SERVIDOR:8096` (ou a porta configurada), crie o administrador
e adicione `/media/movies` e `/media/tv`. Aguarde a varredura da biblioteca.
Recrie os demais usuários e siga a seção Emby de [media-setup.md](media-setup.md)
para configurar reprodução e aceleração por GPU.

No Seerr, a conexão nova é do tipo **Emby**, no endereço `http://emby:8096`.
A troca do Compose não altera a configuração persistente do Seerr. Confira se
a versão instalada oferece migração de servidor antes de trocar a conexão;
não apague `CONFIG_ROOT/seerr` nem edite seu banco para forçar a troca.
Se não houver essa opção, faça um backup e trate a migração do Seerr
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
