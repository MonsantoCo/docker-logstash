#! /usr/bin/env bash
# Logstash startup file.

# Fail fast, including pipelines
set -eo pipefail

# Logstash setup
LS_HOME=${LS_HOME:-"/opt/logstash"}
LS_CFG_BASE_DIR=${LS_CFG_BASE_DIR:-"/etc/logstash"}
LS_CFG_SSL_DIR=${LS_CFG_SSL_DIR:-"${LS_CFG_BASE_DIR}/.ssl"}
LS_CFG_FILE_DIR=${LS_CFG_FILE_DIR:-"${LS_CFG_BASE_DIR}/conf.d"}
LS_CFG_FILE=${LS_CFG_FILE:-"${LS_CFG_FILE_DIR}/logstash.conf"}

# Logstash-Forwarder setup
LS_SSL_CERTIFICATE=${LS_SSL_CERTIFICATE:-"${LS_CFG_SSL_DIR}/logstash-forwarder.crt"}
LS_SSL_KEY=${LS_SSL_KEY:-"${LS_CFG_SSL_DIR}/logstash-forwarder.key"}

getLSConfig() {
  # Download the config file, if given a URL
  if [ ! -z "$LS_CFG_URL" ]; then
    echo "[LS] Downloading logstash config file from ${LS_CFG_URL}"
    curl -sSL --output ${LS_CFG_FILE} ${LS_CFG_URL}
    if [ $? -ne 0 ]; then
      echo "[LS] Failed to download ${LS_CFG_URL} exiting."
      exit 1
    fi
  fi
}

getLSKeys() {
  # Download SSL cert if given a URL
  if [ ! -z "$LSF_CERT_URL" ]; then
    echo "[LS] Downloading logstash-forwarder cert from ${LSF_CERT_URL}"
    curl -sSL --output ${LS_SSL_CERTIFICATE} ${LSF_CERT_URL}
    if [ $? -ne 0 ]; then
      echo "[LS] Failed to download ${LSF_CERT_URL} exiting."
      exit 1
    fi
  fi
  # Download SSL key if given a URL
  if [ ! -z "$LSF_KEY_URL" ]; then
    echo "[LS] Downloading logstash-forwarder key from ${LSF_KEY_URL}"
    curl -sSL --output ${LS_SSL_KEY} ${LSF_KEY_URL}
    if [ $? -ne 0 ]; then
      echo "[LS] Failed to download ${LSF_KEY_URL} exiting."
      exit 1
    fi
  fi
}

processLSenv() {
  # Process environment variables
  for VAR in `env`; do
    if [[ "$VAR" =~ ^LS_ && ! "$VAR" =~ ^LS_CFG_ && ! "$VAR" =~ ^LS_VERSION && ! "$VAR" =~ ^LS_HOME && ! "$VAR" =~ ^LS_USER && ! "$VAR" =~ ^LS_GROUP && ! "$VAR" =~ ^LS_COLORS ]]; then
      LS_CONFIG_VAR=$(echo "$VAR" | sed -r "s/LS_(.*)=.*/\1/g")
      LS_ENV_VAR=$(echo "$VAR" | sed -r "s/(.*)=(.*)/\2/g" | sed -e 's|,|","|g')

      if egrep -q "$LS_CONFIG_VAR" $LS_CFG_FILE; then
        sed -e "s|$LS_CONFIG_VAR|${LS_ENV_VAR}|g" -i $LS_CFG_FILE
      else
        echo "[LS] Substitute variable ${LS_CONFIG_VAR} not found in ${LS_CFG_FILE}."
      fi
    fi
  done
}

checkLSConfig() {
  # Check/validate config file
  echo "[LS] Valiting Logstash agent with config file ${LS_CFG_FILE}."
  ${LS_HOME}/bin/logstash agent -t -f ${LS_CFG_FILE}
  if [ $? -ne 0 ]; then
    echo "[LS] Invalid ${LS_CFG_FILE} file, exiting."
    exit 1
  fi
}

# Fix for SSL certs issue in LS 1.5.3+
curl -sSL http://curl.haxx.se/ca/cacert.pem --output /etc/ssl/certs/cacert.pem
export SSL_CERT_FILE=/etc/ssl/certs/cacert.pem

# Run process, if `docker run` first argument start with `--` the user is passing launcher arguments
if [[ "$1" == "-"* || -z $1 ]]; then
  getLSConfig
  processLSenv
  getLSKeys
  checkLSConfig
  exec /opt/logstash/bin/logstash -f $LS_CFG_FILE "$@"
else
  exec "$@"
fi
