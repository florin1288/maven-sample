#!/usr/bin/env bash

# description: This is the common environmental variable getter

# We need to setup some script level variables, ie. top level of install, property locations
export INSTALL_BASE=`cd $(dirname $0)/..; pwd`
export PROJECT_NAME=@server.name@
export PROJECT_VERSION=@project.version@
export OVERRIDE_FOLDER=@override.folder@
export OVERRIDE_NAME=@override.name@
export OVERRIDE_BASE=${OVERRIDE_BASE-~/conf}
export CONFIG_OVERRIDE="${CONFIG_OVERRIDE-${OVERRIDE_BASE}/${OVERRIDE_FOLDER}/${OVERRIDE_NAME}-override.properties}"
export CONFIG_DEFAULTS="${CONFIG_DEFAULTS-${INSTALL_BASE}/config/${OVERRIDE_NAME}.properties}"

# We want to source our 'environmental variables', lets check the config files
ENV_FILE=$(mktemp)
if [[ -f ${ENV_FILE} ]]; then
    rm -f ${ENV_FILE}
fi

if [[ -f ${CONFIG_DEFAULTS} ]]; then
    TEMPFILE=${ENV_FILE}
    cat ${CONFIG_DEFAULTS} | tr -d '\r' | grep -v '^#' | grep -v '^$' |
while read LINE ; do
    PROPERTY=${LINE%%=*}
    if [[ "$PROPERTY" =~ ^[^-]*$ ]]; then
        VALUE=${LINE#*=}
        echo "${PROPERTY//./_}=\$'${VALUE//\'/\'}'"
    fi
done > ${TEMPFILE}
    source ${TEMPFILE}
fi

if [[ -f ${CONFIG_OVERRIDE} ]]; then
    TEMPFILE=${ENV_FILE}
    cat ${CONFIG_OVERRIDE} | tr -d '\r' | grep -v '^#' | grep -v '^$' |
while read LINE ; do
    PROPERTY=${LINE%%=*}
    if [[ "$PROPERTY" =~ ^[^-]*$ ]]; then
        VALUE=${LINE#*=}
        echo "${PROPERTY//./_}=\$'${VALUE//\'/\'}'"
    fi
done >> ${TEMPFILE}
    source ${TEMPFILE}
fi

rm ${ENV_FILE}


# Environmental Defaults
export LOG_LOCATION=${log_location-/sites/log/${PROJECT_NAME}}
export LOG_STDOUT=${log_file-/dev/null}
export DEBUG_OPTS=${debug_opts}


# Let the user know what's going on
if [[ ! -z $1 ]]; then
   echo "
${PROJECT_NAME} - ${PROJECT_VERSION}
==================
  INSTALL_BASE             = ${INSTALL_BASE}
  PROPERTIES_BASE          = ${PROPERTIES_BASE}
  CONFIG_DEFAULTS          = ${CONFIG_DEFAULTS}
  CONFIG_OVERRIDE          = ${CONFIG_OVERRIDE}
  LOG_LOCATION             = ${LOG_LOCATION}
==================
  DEBUG_OPTS               = ${DEBUG_OPTS}
==================
"
fi

# Production Support Protection 1.0
if [[ `whoami` == 'root' ]]; then
   echo "You Muppet! Don't try and start java apps as root!"
   exit 1
fi

# Create logs folder
if [[ ! -L ${INSTALL_BASE}/logs ]]; then
  mkdir -p ${LOG_LOCATION}
  ln -s ${LOG_LOCATION} ${INSTALL_BASE}/logs
fi

sleep 2
