#!/bin/bash
set -e

teardown() {
	# Always run the stop command on termination
	${SPLUNK_HOME}/bin/splunk stop 2>/dev/null || true
}

trap teardown SIGINT SIGTERM

watch_for_failure(){
	if [[ $? -eq 0 ]]; then
		sh -c "echo 'started' > /tmp/splunk-container.state"
	fi
	echo ===============================================================================
	echo
	# Any crashes/errors while Splunk is running should get logged to splunkd_stderr.log and sent to the container's stdout
	tail -n 0 -f ${SPLUNK_HOME}/var/log/splunk/splunkd_stderr.log &
	wait
}

start() {
    trap teardown EXIT
	if [ -z $SPLUNK_INDEX ]; then
	echo "'SPLUNK_INDEX' env variable is empty or not defined. Should be 'dev' or 'prd'." >&2
	exit 1
	else
	sed -e "s/@index@/$SPLUNK_INDEX/" -i ${SPLUNK_HOME}/etc/system/local/inputs.conf
	fi
	sed -e "s/@hostname@/$(cat /etc/hostname)/" -i ${SPLUNK_HOME}/etc/system/local/inputs.conf
    sh -c "echo 'starting' > /tmp/splunk-container.state"
	${SPLUNK_HOME}/bin/splunk start
    watch_for_failure
}

restart(){
    trap teardown EXIT
	sh -c "echo 'restarting' > /tmp/splunk-container.state"
  	${SPLUNK_HOME}/bin/splunk stop 2>/dev/null || true
	${SPLUNK_HOME}/bin/splunk start
	watch_for_failure
}

case "$1" in
	start|start-service)
		shift
		start $@
		;;
	restart)
	    shift
	    restart $@
	    ;;
	bash|splunk-bash)
		/bin/bash --init-file ${SPLUNK_HOME}/bin/setSplunkEnv
		;;
esac


