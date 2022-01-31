#!/bin/bash

# Fail on any error (but not errexit, as we want to be gracefull!)
set -uo pipefail
echo "FILENAME: init.sh"
DATAVERSE_SERVICE_HOST=${DATAVERSE_SERVICE_HOST:-"dataverse"}
DATAVERSE_SERVICE_PORT_HTTP=${DATAVERSE_SERVICE_PORT_HTTP:-"8080"}
DATAVERSE_URL=${DATAVERSE_URL:-"http://${DATAVERSE_SERVICE_HOST}:${DATAVERSE_SERVICE_PORT_HTTP}"}

SOLR_SERVICE_HOST=${SOLR_SERVICE_HOST:-"solr"}
SOLR_SERVICE_PORT_HTTP=${SOLR_SERVICE_PORT_HTTP:-"8983"}
SOLR_URL=${SOLR_URL:-"http://${SOLR_SERVICE_HOST}:${SOLR_SERVICE_PORT_HTTP}"}

TARGET="/var/solr/data/schema"

# Check API key secret is available
if [ ! -s "/var/solr/data/scripts/schema/api/key" ]; then
  echo "No API key present. Failing."
  exit 126
fi
UNBLOCK_KEY=`cat /var/solr/data/scripts/schema/api/key`

echo "Re-copy our initial schema.xml to freshly created empty-dir, which has a symlink to coll1/conf/schema.xml"
cp ${SOLR_HOME}/schema.xml ${TARGET}/schema.xml

echo "Updating schema (updateSchemaMDB) with: -t ${TARGET}, -s ${SOLR_URL}, -u ${UNBLOCK_KEY}, -d ${DATAVERSE_URL}"

${SCHEMA_SCRIPT_DIR}/updateSchemaMDB.sh \
  -t "$TARGET" \
  -s "$SOLR_URL" \
  -u "$UNBLOCK_KEY" \
  -d "$DATAVERSE_URL" \
  || echo "Failing gracefully to allow startup."
