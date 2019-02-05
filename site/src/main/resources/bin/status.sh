#!/usr/bin/env bash


# define service
SDC_SERVICE=${sdc_service-"sdc.service"}


# get the status
systemctl list-units | grep -Fq ${SDC_SERVICE}
if [[ $? -ne 0 ]]; then
  echo "Service ${SDC_SERVICE} doesn't exist"
  exit 1
fi

systemctl status ${SDC_SERVICE}