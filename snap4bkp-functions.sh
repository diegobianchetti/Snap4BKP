#!/bin/bash

# função que cria a lista com ID
# das instancias em execução
function lista_instancias () {

unset instancesID
unset ListaInstancesID

count=0
for instancesID in $(curl --silent "https://api.vultr.com/v2/instances" \
                 -X GET \
                 -H "Authorization: Bearer ${VULTR_API_KEY}" \
                 | jq '.instances[] | {ID: .id}' \
                 | cut -d":" -f2 | tr -d {}\
          )
  do
    ListaInstancesID[$count]=$(echo $instancesID)
    count=$(($count+1))
  done
}


# cria snapshots a partir do array com ID
# das instancias presentes na VULTR
function cria_snapshots () {

  unset IDinstancia
  unset ID
  unset NOME

  # cria arquivo de log para cada execução de criação
  touch $create_snapshot_log_file

  for IDinstancia in ${ListaInstancesID[@]}
  do

  ID=$(echo $IDinstancia | tr -d \")
  NOME=$(curl --silent "https://api.vultr.com/v2/instances/$ID" \
    -X GET \
    -H "Authorization: Bearer ${VULTR_API_KEY}"\
    |  jq '.[] | .label' | tr -d \")

  curl --silent "https://api.vultr.com/v2/snapshots" \
    -X POST \
    -H "Authorization: Bearer ${VULTR_API_KEY}" \
    -H "Content-Type: application/json" \
    --data '{
      "instance_id" : "'${ID}'",
      "description" : "'${PrefixoSnapshotsBKP}-${NOME}-${DataHora}'"}'

  echo "instance_id: ${ID}" >> $create_snapshot_log_file
  echo "description: ${PrefixoSnapshotsBKP}-${NOME}-${DataHora}" >> $create_snapshot_log_file

  done
}


# Cria array com ID dos Snapshots que fazem parte do sistema de BACKUP
# (possuem "$PrefixoSnapshotsBKP") onde os mais antigos que o
# limite (5) serão apagados
function verifica_reservados () {

  unset BKPsnapshotID
  unset ListaBKPsnapshotsID
  count=0


  # cria arquivo de log para cada execução de remoção
  touch $remove_snapshot_log_file

  for BKPsnapshotID in $(curl  --silent "https://api.vultr.com/v2/snapshots" \
                          -X GET \
                          -H "Authorization: Bearer ${VULTR_API_KEY}" \
                            | jq '.snapshots[] | select( .description | contains("'${PrefixoSnapshotsBKP}'")) | .id' \
                            | tr -d \"
                      )
    do
      # verifica se o Snapshot está na lista de Reservados
      if [ -n "${SnapshotsReservados[$BKPsnapshotID]}" ]
        then
          NOME_RESERVADO=$(curl --silent "https://api.vultr.com/v2/snapshots/$BKPsnapshotID" \
              -X GET \
              -H "Authorization: Bearer ${VULTR_API_KEY}" \
              | jq '.[] | .description')
          printf 'instance_id: %s\n' "$BKPsnapshotID" >> $snapshots_reservados_log_file
          printf 'description: %s está na lista de Reservados!\n' "$NOME_RESERVADO" >> $snapshots_reservados_log_file
        else
          # cria a lista dos SnapShots para remoção
          ListaBKPsnapshotsID[$count]=$(echo $BKPsnapshotID)
      fi

      count=$(($count+1))
    done
}


# essa é a lista de snapshots que fazem parte do sistema de backup
# e não estão reservados - ou seja lista para apagar
# a partir dessa lista ainda preciso fazer o filtro para remover
# somente os bkps mais aintigos que o limite
function remove_snapshots_antigos () {

  xcount=0

  for SnapIDparaDeletar in ${ListaBKPsnapshotsID[@]}
  do
    NOMES_PARA_DELETAR=$(curl --silent "https://api.vultr.com/v2/snapshots/$SnapIDparaDeletar" \
        -X GET \
        -H "Authorization: Bearer ${VULTR_API_KEY}" \
        | jq '.[] | .description')
    # retira a hora (ultima parte do nome separada por "-")
    NOME_REV_REV=$(echo $NOMES_PARA_DELETAR | rev | cut -d"-" -f2- | rev)
    # recebe a data (ultima parte do nome separada por "-")
    DATA_NOME_PARA_DELETAR=$(echo ${NOME_REV_REV##*-})

    if [ $(echo $DATA_NOME_PARA_DELETAR) -lt $Data_para_Deletar ]
      then
        echo "instance_id: $SnapIDparaDeletar" >> $remove_snapshot_log_file
        echo "description: $NOMES_PARA_DELETAR - marcado para DELETAR!" >> $remove_snapshot_log_file
        ListaDELETAR_snapID_ANTIGOS[$xcount]=$(echo $SnapIDparaDeletar)
        xcount=$(($xcount+1))
    fi
  done


  # execução do DELETE
  for DELETE_SNAP_ID in ${ListaDELETAR_snapID_ANTIGOS[@]}
  do
  curl --silent "https://api.vultr.com/v2/snapshots/$DELETE_SNAP_ID" \
        -X DELETE \
        -H "Authorization: Bearer ${VULTR_API_KEY}"
  echo "$DELETE_SNAP_ID - SnapShot REMOVIDO!" >> $remove_snapshot_log_file

  done
}
