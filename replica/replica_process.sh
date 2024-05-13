#!/bin/bash

export JAVA_HOME=/usr/lib/jvm/jre-11
export JAVA_OPTS="-Xmx2048M -Xms2048M"

# db password
ENV_FILE=~/replica/.env

export $(grep -v '^#' $ENV_FILE | xargs -d '\n')

option_file=~/replica/replicadb.conf

CONTRACT_TABLES="$(echo "${replica_tables[@]}")"

for table in "${CONTRACT_TABLES[@]}"; do
  /home/ec2-user/replica/bin/replicadb --sink-connect=$SINK_CONNECT --source-connect=$SOURCE_CONNECT --source-table=addresses --source-query="SELECT * FROM ${table}" --options-file ${option_file}
done

echo "done"