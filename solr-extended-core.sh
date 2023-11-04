#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Configure a Solr ${CORE} and then run solr in the foreground
set -euo pipefail
printf "\n---------------------- running $0 ----------------------\n"
printf "\n\n"

if [[ "${VERBOSE:-}" == "yes" ]]; then
    set -x
fi

# Could set env-variables for solr-fg
init-var-solr
source run-initdb

CORE_API="http://localhost:${SOLR_PORT}/solr/#/${CORE}/core-overview"
CORE_SCHEMA_URL="http://localhost:${SOLR_PORT}/solr/${CORE}/schema?commit=true"
CORE_UPDATE_URL="http://localhost:${SOLR_PORT}/solr/${CORE}/update?commit=true"

printf "read from environment_variables \n 
  CORE=$CORE \n 
  CORE_DIR=$CORE_DIR \n 
  CORE_SCHEMA=$CORE_FIELDS \n 
  CORE_SAMPLE_DATA=$CORE_SAMPLE_DATA \n
  CORE_SCHEMA_URL=$CORE_SCHEMA_URL \n
  CORE_UPDATE_URL=$CORE_UPDATE_URL \n"
printf "\n"

if [ -d $CORE_DIR ]; then
  echo "$CORE exists; skipping ${CORE} creation"
else
  echo "CORE $CORE DOES NOT EXISTS, we should create it now"
  start-local-solr

  echo "creating CORE $CORE"
  /opt/solr/bin/solr create -c "$CORE"
  printf "CORE ${CORE} created successfully \n"
  
  post_args=()
  if [[ -n "${SOLR_PORT:-}" ]]; then
    post_args+=(-p "$SOLR_PORT")
  fi
  
  echo "creating ${CORE_FIELDS} schema fields"
  curl -X POST -H 'Content-type:application/json' -d @"${CORE_FIELDS}" ${CORE_SCHEMA_URL}
  printf "\n"
  printf "CORE ${CORE} schema fields created successfully \n"

  echo "indexing CORE_SAMPLE_DATA ${CORE_SAMPLE_DATA}"
  # ! THIS IS FLATENNING THE ARRAYS commentaries.id, commentaries.comment, Use the JSON post instead
  #/opt/solr/bin/post -c $CORE -commit yes ${CORE_SAMPLE_DATA}
  curl -X POST -H 'Content-type:application/json' -d @"${CORE_SAMPLE_DATA}" ${CORE_UPDATE_URL}
  printf "\n"
  printf "CORE ${CORE} CORE_SAMPLE_DATA created successfully \n"
  
  if [ $SOLR_PORT -gt 1024 ]; then
    stop-local-solr
    # solr stop -p $SOLR_PORT
  else
    printf "force stopping SOLR on port $SOLR_PORT \n"
    pgrep -f java | xargs kill -9
    sleep 10
    echo "pgrep -f java $(pgrep -f java)" 
  fi

  # check the core_dir exists; otherwise the detecting above will fail after stop/start
  if [ ! -d "$CORE_DIR" ]; then
    echo "Missing $CORE_DIR"
    exit 1
  fi
fi

exec solr-fg