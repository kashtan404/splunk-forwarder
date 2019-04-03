#!/bin/bash
if [[ "" == "$NO_HEALTHCHECK" ]]; then
	#If NO_HEALTHCHECK is NOT defined, then we want the healthcheck
	state="$(< $CONTAINER_ARTIFACT_DIR/splunk-container.state)"

	case "$state" in
	running|started)
	    curl -m 30 -f -k https://localhost:8089/
	    exit $?
	;;
	*)
	    exit 1
	esac
else
	#If NO_HEALTHCHECK is defined, ignore the healthcheck
	exit 0
fi
