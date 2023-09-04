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

if [[ "${VERBOSE:-}" == "yes" ]]; then
    set -x
fi

# Could set env-variables for solr-fg
/opt/solr/docker/scripts/init-var-solr
source /opt/solr/docker/scripts/run-initdb

solrdata=/var/solr/data
CORE=${CORE_NAME}
CORE_DIR="$solrdata/${CORE}"
CORE_CONF_DIR="${CORE_DIR}/conf"
CORE_SCHEMA_URL="http://localhost:8983/solr/${CORE}/schema?commit=true"
CORE_UPDATE_URL="http://localhost:8983/solr/${CORE}/update?commit=true"

echo "read from env CORE=$CORE, CORE_DIR=$CORE_DIR, CORE_SCHEMA=$CORE_FIELDS, CORE_SAMPLE_DATA=$CORE_SAMPLE_DATA"

if [ -d "$CORE_DIR" ]; then
  echo "$CORE_DIR exists; skipping ${CORE} creation"
else
  start-local-solr
  echo "Creating $CORE"
  /opt/solr/bin/solr create -c "$CORE"
  echo "Created $CORE"
  echo "Loading example data"
  post_args=()
  if [[ -n "${SOLR_PORT:-}" ]]; then
    post_args+=(-p "$SOLR_PORT")
  fi
  
  echo "creating ${CORE}'s schema fields"
  curl -X POST -H 'Content-type:application/json' -d @"${CORE_FIELDS}" ${CORE_SCHEMA_URL}

  echo "indexing ${CORE_SAMPLE_DATA}"
  # ! THIS IS FLATENNING THE ARRAYS commentaries.id, commentaries.comment, Use the JSON post instead
  #/opt/solr/bin/post -c $CORE -commit yes ${CORE_SAMPLE_DATA}
  curl -X POST -H 'Content-type:application/json' -d @"${CORE_SAMPLE_DATA}" ${CORE_UPDATE_URL}
  
  echo "Loaded example data"
  stop-local-solr

    # check the core_dir exists; otherwise the detecting above will fail after stop/start
    if [ ! -d "$CORE_DIR" ]; then
        echo "Missing $CORE_DIR"
        exit 1
    fi
fi

exec solr-fg