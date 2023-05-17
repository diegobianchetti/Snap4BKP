# Snap4BKP

Conjunto de scripts em bash que interagem com a API da VULTR (vultr.com) para criar e administrar SnapShots das instancias de uma conta.

#### Funcionalidades

- Atualmente o sistema funciona criando um SnapShot por instância toda vez que executado.

- O limite de backups por instancia é definido em dias no arquivo configuração.

- Remoção dos backups mais antigos que o limite definido.

- Possui uma lista de SnapShots reservados, ou seja, que não serão apagados mesmo que mais antigos que os definidos no limite.

- Geração de logs de snapshots criados, removidos e reservados.


#### Formato de nome padrão (snapshots)

O SnapShot é gerado com um formato de nome padrão que permite a administação dos SnapShots. O nome é composto conforme exemplo abaixo:

Composição do nome do SnapShot: **PrefixoSnapshotsBKP-
NomeInstancia-DataHora**

Onde:<br>
**PrefixoSnapshotsBKP:** Está denfinido no arquivo de configuração<br>
**NomeInstancia:** É obtido a partir da descrição da instancia<br>
**DataHora:** Gerados pelo sistema<br>

```
Nome da instancia: "NOME-Servidor"

Nome do SnapShot:
snap4BKP-NOME-Servidor-20230511-230547
```

**IMPORTANTE:** Por definição, o nome das Instancias deve ser separado por traço "-"

### Organização do sistema

Snap4BKP é um conjunto simples de scripts em bash que está dividido atualmente em 3 arquivos.

**config.snap4bkp:** Arquivo de configuração para VULTR_API_KEY, Prefixo, Limite de backups por instância e Lista de snapshots reservados. <br>
**snap4bkp-functions.sh:** Arquivo de funções, onde está toda a lógica do sistema de backup. <br>
**snap4bkp.sh:** Arquivo que roda/executa o sistema de criação e administração dos SnapShots. <br>


### Instalação

#### Pré-requisitos
```
sudo apt -y install jq
```

#### Copia do sistema e configuração

- Copiar o diretório Snap4BKP completo para o $HOME do usuário que irá executar o sistema de backup.

- Configurar a ```crontab``` do servidor para executar o sistema, conforme exemplo abaixo.

```
crontab -e
```
Adicione as linhas abaixo ao final da CRON para executar o sistema 1x por dias às 23:05.
```
# executa sistema de backup para instancias rodando na VulTR
05 23 * * * bash /home/$USER/Snap4BKP/snap4bkp.sh
```


#### No Debian/Ubuntu:

O comando SH no Debian/Ubuntu aponta para o "dash" em vez de bash por padrão. E como o dash é mais leve que o bash, ele suporta apenas as funções básicas do shell para acelerar a inicialização. Por exemplo, não inclui inicialização de arrays. O que gera um erro de sintaxe.

**Solução:**

Dash está causando problemas. A solução é cancelar o dash.

```
sudo dpkg-reconfigure dash
```
Selecione "NÃO" nas opções e pronto!


# ROADMAP - próximos passos

Estou adicionando funcionalidades e testes ao sistema, como por exemplo:

- geração de lista dos snapshots que não fazem parte do sistema de backup (para gerar lista de reservados)
- backup de uma única instancia (onse-shot backup)
- restore de backup (selecionar e restaurar um backup específico)
- remover logs antigos (mais de 30 dias)
