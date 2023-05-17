#!/bin/bash

# carrengando arquivo de configuração
source ./config.snap4bkp

# carrengando arquivo de funções
source ./snap4bkp-functions.sh

## execução de criçao dos SnapShots
lista_instancias
#cria_snapshots

## execução de remoção dos SnapShots antigos
verifica_reservados
remove_snapshots_antigos
