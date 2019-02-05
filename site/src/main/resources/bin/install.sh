#!/usr/bin/env bash


INSTALL_BASE=${INSTALL_BASE-$(cd $(dirname $0)/..; pwd)}
. ${INSTALL_BASE}/bin/common.sh echo


# define paths
LOCAL_RUNTIME_PROPERTIES=${local_runtime_properties-"config/runtime"}
STREAMSETS_RUNTIME_PROPERTIES=${streamsets_runtime_properties-"/etc/sdc/runtime"}

LOCAL_SDC_PROPERTIES=${local_sdc_properties-"config/streamsets.properties"}
STREAMSETS_SDC_PROPERTIES=${streamsets_sdc_properties-"/etc/sdc/sdc.properties"}

LOCAL_EXTRA_LIBS=${local_extra_libs-"lib"}
STREAMSETS_EXTRA_LIBS=${streamsets_extra_libs-"/opt/streamsets-datacollector/streamsets-libs-extras"}


# create_symlink source destination
create_symlink() {
  if [[ -L $2 ]]; then
    echo "Symlink already created: $2 links to $1"
    return 1
  fi
  if [[ -f $2 ]]; then
    echo "Removing file $2"
    rm $2
  fi
  if [[ -d $2 ]]; then
    echo "Removing directory $2"
    rm -r $2
  fi
  echo "Creating symlink $2 to $1"
  ln -s $1 $2
}


echo "Adding runtime properties"
create_symlink ${INSTALL_BASE}/${LOCAL_RUNTIME_PROPERTIES} ${STREAMSETS_RUNTIME_PROPERTIES}

echo "Adding sdc properties"
create_symlink ${INSTALL_BASE}/${LOCAL_SDC_PROPERTIES} ${STREAMSETS_SDC_PROPERTIES}

echo "Adding extra libs"
create_symlink ${INSTALL_BASE}/${LOCAL_EXTRA_LIBS} ${STREAMSETS_EXTRA_LIBS}

# add Hadoop configs
SRC_HADOOP_CONF_DIR=${src_hadoop_conf_dir-"${INSTALL_BASE}/hadoop/conf"}
SRC_HIVE_CONF_DIR=${src_hive_conf_dir-"${INSTALL_BASE}/hive/conf"}

DST_HADOOP_CONF_DIR=${dst_hadoop_conf_dir-"/etc/hadoop/conf"}
DST_HIVE_CONF_DIR=${dst_hive_conf_dir-"/etc/hive/conf"}

AMBARI_SERVER=${ambari_server}
AMBARI_USER=${ambari_user}
AMBARI_PASS=${ambari_pass}

HDFS_CONFIGS_URL=${hdfs_configs_url-"${AMBARI_SERVER}/api/v1/clusters/rtdw_ltb/services/HDFS/components/HDFS_CLIENT?format=client_config_tar"}
HIVE_CONFIGS_URL=${hive_configs_url-"${AMBARI_SERVER}/api/v1/clusters/rtdw_ltb/services/HIVE/components/HIVE_CLIENT?format=client_config_tar"}

echo "Downloading Hadoop client configs from Ambari server"
curl --user ${AMBARI_USER}:${AMBARI_PASS} -H "X-Requested-By: ambari" -X GET ${HDFS_CONFIGS_URL} -o HDFS_CLIENT-configs.tar.gz

mkdir -p ${SRC_HADOOP_CONF_DIR}
tar -xzvf HDFS_CLIENT-configs.tar.gz -C ${SRC_HADOOP_CONF_DIR}
if [[ $? -eq 0 ]]; then
  mkdir -p ${DST_HADOOP_CONF_DIR}
  create_symlink ${SRC_HADOOP_CONF_DIR} ${DST_HADOOP_CONF_DIR}
fi

echo "Downloading Hive client configs from Ambari server"
curl --user ${AMBARI_USER}:${AMBARI_PASS} -H "X-Requested-By: ambari" -X GET ${HIVE_CONFIGS_URL} -o HIVE_CLIENT-configs.tar.gz

mkdir -p ${SRC_HIVE_CONF_DIR}
tar -xzvf HIVE_CLIENT-configs.tar.gz -C ${SRC_HIVE_CONF_DIR}
if [[ $? -eq 0 ]]; then
  mkdir -p ${DST_HIVE_CONF_DIR}
  cp ${SRC_HADOOP_CONF_DIR}/* ${SRC_HIVE_CONF_DIR}/
  create_symlink ${SRC_HIVE_CONF_DIR} ${DST_HIVE_CONF_DIR}
fi

