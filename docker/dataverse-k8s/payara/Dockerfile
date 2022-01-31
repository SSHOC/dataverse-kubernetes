# Copyright 2019 Forschungszentrum Jülich GmbH
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0

FROM payara/server-full:5.2021.4-jdk11
LABEL maintainer="FDM FZJ <forschungsdaten@fz-juelich.de>, DANS <vyacheslav.tykhonov@dans.knaw.nl>, SSHOC <wilko.steinhoff@dans.knaw.nl>"

# From base image:
# PAYARA_DIR=/opt/payara/appserver
# DOMAIN_NAME = domain1
# HOME_DIR = /opt/payara
# DEPLOY_DIR = /opt/payara/deployments
# SCRIPT_DIR = /opt/payara/scripts
# PREBOOT_COMMANDS=/opt/payara/config/pre-boot-commands.asadmin
# POSTBOOT_COMMANDS=/opt/payara/config/post-boot-commands.asadmin


ARG VERSION=5.9
ARG DOMAIN=domain1
ARG PGDRIVER_PKG=https://jdbc.postgresql.org/download/postgresql-42.2.19.jar
ARG DUMPS_DIR=/dumps
ARG DATAVERSE_PKG=https://github.com/IQSS/dataverse/releases/download/v${VERSION}/dvinstall.zip

ENV DATA_DIR=/data\
    DOCROOT_DIR=/opt/docroot\
    METADATA_DIR=/metadata\
    SECRETS_DIR=/secrets\    
    DOMAIN_DIR=${PAYARA_DIR}/glassfish/domains/${DOMAIN_NAME}\
    DATAVERSE_VERSION=${VERSION}\
    # Make heap dumps on OOM appear in DUMPS_DIR
    JVM_ARGS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${DUMPS_DIR}"

# Create basic paths:
USER root

RUN mkdir -p ${DATA_DIR} ${METADATA_DIR} ${DOCROOT_DIR} ${SECRETS_DIR} ${DUMPS_DIR} && \
    chown -R payara: ${DATA_DIR} ${METADATA_DIR} ${DOCROOT_DIR} ${SECRETS_DIR} ${DUMPS_DIR}

# Install prerequisites:
RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qqy install postgresql-client jq imagemagick curl wget unzip ed bc original-awk

# Install esh template engine from Github:
RUN wget --no-verbose -O esh https://raw.githubusercontent.com/jirutka/esh/v0.3.1/esh && \
    echo 'ad5dfa4a8971d66dd563dff3c63c8241878d5108  esh' | sha1sum -c - && \
    chmod +x esh && mv esh /usr/local/bin

# Install PostgreSQL JDBC driver in AppServer:
# TODO: remove this once upstream includes the Postgres Client lib in the WAR.
USER payara
RUN wget --no-verbose -O postgresql.jar ${PGDRIVER_PKG} && \
    mv postgresql.jar ${PAYARA_DIR}/glassfish/lib

# Make docroot of Payara reside in higher level directory for easier targeting.
# Due to IQSS/dataverse-kubernetes#177: create the generated paths so they are
# writeable by us. TBR with #178.
RUN rm -rf ${DOMAIN_DIR}/docroot && \
    ln -s ${DOCROOT_DIR} ${DOMAIN_DIR}/docroot && \
    mkdir -p ${DOMAIN_DIR}/generated/jsp/dataverse

# Retrieve the Dataverse install package, extract and remove ZIP,
# symlink WAR file and remove Harvard custom metadatablocks.
RUN cd ${HOME_DIR} && \
    wget --no-verbose -O dvinstall.zip ${DATAVERSE_PKG} && \
    unzip -qq dvinstall.zip -d ./ && \
    rm dvinstall.zip && \
    ln -s ${HOME_DIR}/dvinstall/dataverse.war ${DEPLOY_DIR}/dataverse.war && \
    find . -iname "custom*.tsv" -delete

## COPY .tsv file(s) to the proper location.
# ADD https://raw.githubusercontent.com/IQSS/dataverse-docker/master/config/schemas/CESSDA_CMM.tsv /opt/payara/dvinstall/data/metadatablocks/cessda_cmm.tsv
# COPY --chown=payara:payara docker/dataverse-k8s/payara/cmdb/*.tsv /opt/payara/dvinstall/data/metadatablocks/

# Copy across docker scripts:
COPY --chown=payara:payara docker/dataverse-k8s/bin/* docker/dataverse-k8s/payara/bin/*.sh ${SCRIPT_DIR}/
RUN chmod +x ${SCRIPT_DIR}/*
