#!/usr/bin/env bash


# define service
SDC_SERVICE=${sdc_service-"sdc.service"}


# try start the service
systemctl list-units | grep -Fq ${SDC_SERVICE}
if [[ $? -ne 0 ]]; then
  echo "Service ${SDC_SERVICE} doesn't exist"
  exit 1
fi

if [[ $(systemctl show -p SubState ${SDC_SERVICE} | sed 's/SubState=//g') == "running" ]]; then
  echo "Service ${SDC_SERVICE} is already running"
  exit 1
fi

systemctl start ${SDC_SERVICE}