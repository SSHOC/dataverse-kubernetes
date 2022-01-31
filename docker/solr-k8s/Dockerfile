# Copyright 2019 Forschungszentrum Jülich GmbH
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0

FROM solr:8.9.0

LABEL maintainer="FDM FZJ <forschungsdaten@fz-juelich.de>, SSHOC <wilko.steinhoff@dans.knaw.nl>"

# From base image:
# SOLR_HOME=/var/solr/data

ARG WEBHOOK_VERSION=2.8.0
ARG TINI_VERSION=v0.19.0
ARG DV_VERSION=5.9
ARG COLLECTION=collection1
ENV SOLR_OPTS="-Dsolr.jetty.request.header.size=102400"\
    COLLECTION_DIR=${SOLR_HOME}/${COLLECTION}\
    SCHEMA_DIR=${SOLR_HOME}/schema\
    SCRIPT_DIR=${SOLR_HOME}/scripts\
    DATAVERSE_URL=http://dataverse:8080\
    SOLR_USER="solr"\
    DATAVERSE_PKG=https://github.com/IQSS/dataverse/releases/download/v${DV_VERSION}/dvinstall.zip
ENV SCHEMA_SCRIPT_DIR=${SCRIPT_DIR}/schema

# Create schema store and scripts folder if not present, change permissions
RUN mkdir -p ${SCHEMA_DIR} ${SCRIPT_DIR} ${SCHEMA_SCRIPT_DIR} && \
    chown -R ${SOLR_USER}: ${SCHEMA_DIR} ${SCRIPT_DIR} ${SCHEMA_SCRIPT_DIR}

# Intall Tini
RUN wget --no-verbose -O ${SOLR_HOME}/tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini && \
    chmod +x ${SOLR_HOME}/tini

# Dataverse uses a **hardcoded** core name "collection1", so we need to use it.
# 1) Create core directory
# 2) Copy _default configset
# 3) Create core.properties
RUN mkdir -p ${COLLECTION_DIR} && \
    cp -a ${PWD}/server/solr/configsets/_default/conf ${COLLECTION_DIR} && \
    echo "name=${COLLECTION}" > ${COLLECTION_DIR}/core.properties

# Download dvinstall.zip, extract, copy schema and config, remove install files
# Copy script for schema creation.
RUN wget --no-verbose -O ${SOLR_HOME}/dvinstall.zip ${DATAVERSE_PKG} && \
    unzip -qq ${SOLR_HOME}/dvinstall.zip -d ${SOLR_HOME} && \
    mv ${SOLR_HOME}/dvinstall/solrconfig.xml ${COLLECTION_DIR}/conf/solrconfig.xml && \
  	cp ${SOLR_HOME}/dvinstall/schema.xml ${SCHEMA_DIR}/ && \
  	cp ${SOLR_HOME}/dvinstall/schema.xml ${SOLR_HOME}/ && \
    mv ${SOLR_HOME}/dvinstall/update-fields.sh ${SCHEMA_SCRIPT_DIR}/ && \
    rm -rf ${SOLR_HOME}/dvinstall ${SOLR_HOME}/dvinstall.zip

# Create simlink /var/solr/data/schema/schema.xml to ..collection1/conf/schema.xml. The K8s init container will mount the schema.xml again to the empty-dir, to provide it to the main container and it's side-car.
RUN sed -i "s|<jmx />||g" ${COLLECTION_DIR}/conf/solrconfig.xml && \
	ln -s ${SCHEMA_DIR}/schema.xml ${COLLECTION_DIR}/conf/schema.xml

USER root
RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qqy install nano tree bc ed
USER ${SOLR_USER}

### SIDECAR BELONGINGS
# Prepare everything for schema update sidecar
RUN wget --no-verbose -O ${SOLR_HOME}/webhook.tar.gz https://github.com/adnanh/webhook/releases/download/${WEBHOOK_VERSION}/webhook-linux-amd64.tar.gz && \
    tar -xzf ${SOLR_HOME}/webhook.tar.gz --strip-components=1 -C ${SCHEMA_SCRIPT_DIR} && \
    chmod +x ${SCHEMA_SCRIPT_DIR}/webhook && \
    rm ${SOLR_HOME}/webhook.tar.gz
COPY --chown=solr:solr schema ${SCHEMA_SCRIPT_DIR}
RUN chmod +x ${SCHEMA_SCRIPT_DIR}/*.sh
