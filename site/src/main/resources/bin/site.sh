#!/usr/bin/env bash

# description: Start up or shutdown @server.name@.

source /etc/profile
READLINK=$(readlink -f $0)
if [[ $? -ne 0 ]]; then
    echo "readlink failed, trying Mac version greadlink..."
    #readlink failed, need gnu version.
    READLINK=$(greadlink -f $0)
	if [[ $? -ne 0 ]]; then
        echo "If you're on a Mac and you don't have 'greadlink' execute the command: sudo port install coreutils"
        exit 1
    fi
fi
export SITE_BIN=$(dirname $READLINK)
export PYTHON_USER=@python.user@
[[ "$PYTHON_USER" == @*@ ]] && PYTHON_USER=''
export SITE_USER=${SITE_USER-$PYTHON_USER}
[[ -z "${SITE_USER}" ]] && export SITE_USER=esportz

# Ensure it gets run as $SITE_USER
[[ $(whoami) != "$SITE_USER" ]] && exec /sbin/runuser -u "$SITE_USER" "$0" "$@"

EVENT_URL='http://builds.corp-apps.com/audit_ws/api/v1/events/'

_post_event() {
    local event="$1"
	data='{
		"deploy": "@server.name@",
		"host": "'$HOSTNAME'",
		"event": "'$event'",
		"event_time": "'$(date +'%Y-%m-%dT%H:%M:%S')'",
		"deprecated": "false",
		"datacenter": "'$(cut -d'.' -f2 <<<$HOSTNAME)'",
		"user": "'$USER'",
		"feedback": "",
		"reference": ""
	}'
	curl -s -X POST -H "Content-Type: application/json" -d "$data" "$EVENT_URL" >/dev/null
}

case "$1" in
    start)
        if [[ -x ${SITE_BIN}/startup.sh ]]; then
            echo "Starting service..."
            ${SITE_BIN}/startup.sh
            RETVAL=$?
            (( RETVAL == 0 )) || {
                echo 'Failed to start service'
                exit ${RETVAL}
            }
			[[ -x ${SITE_BIN}/startup-extra.sh ]] && {
				${SITE_BIN}/startup-extra.sh
				let "RETVAL |= $?"
			}
            (( RETVAL == 0 )) && _post_event service_start
        fi
        ;;

    stop)
        if [[ -x ${SITE_BIN}/shutdown.sh ]]; then
            echo "Stopping service..."
            ${SITE_BIN}/shutdown.sh
            RETVAL=$?
            if [[ -x ${SITE_BIN}/shutdown-extra.sh ]]; then
                ${SITE_BIN}/shutdown-extra.sh
                let "RETVAL |= $?"
            fi
        fi
        _post_event service_stop
        ;;

    restart)
        ${SITE_BIN}/site.sh stop || {
            echo "Cannot stop service" >&2
            exit 1
        }
        running=1
        while (( running != 0 )); do
            ${SITE_BIN}/site.sh status | grep "@server.name@ stopped"
            running=$?
            sleep 1
            echo "... still running"
        done
        ${SITE_BIN}/site.sh start
        ;;

    version)
        [[ -x ${SITE_BIN}/version.sh ]] && ${SITE_BIN}/version.sh
        ;;

    status)
        if [[ -x ${SITE_BIN}/status.sh ]]; then
            ${SITE_BIN}/status.sh
            exit $?
        else
            RUNNING=$(ps -ef | grep @server.name@-running | grep -v grep | awk '{ print $2 }')
            if [[ -z "$RUNNING" ]]; then
                echo "@server.name@ stopped"
            else
                echo "@server.name@ running"
            fi
            exit 0
        fi
        ;;

    _post-start)
        _post_event service_start
        ;;

    _post-stop)
        _post_event service_stop
        ;;

    *)
        echo "Usage: $0 {start|stop|restart|version|status}"
        exit 1
        ;;
esac

exit $RETVAL
