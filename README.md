# Table of Contents

- [Introduction](#introduction)
    - [Requirements](#requirements)
    - [Collecting information](#collecting-information)
        - [Docker inspect](#docker-inspect)
        - [Docker stats](#docker-stats)
        - [Docker top](#docker-top)
        - [Docker events](#docker-events)
    - [Version](#version)
- [Installation](#installation)
- [Start](#start)
- [Configuration](#configuration)
- [Permissions](#permissions)
- [Dashboards](#dashboards)


## Introduction

This solution builds docker image with preconfigured Splunk Universal Forwarder.
It uses base centos 7 image and includes Docker and Splunk binaries. You should
mount `/var/run/docker.sock` from the host if you want gather various docker stats.

## Requirements

- mount `/var/run/docker.sock` to gather docker stats
- mount `/etc/hostname` to use hostname in the `host` Splunk parameter. Not necessary parameter.
- mount `/var/log` to forward system logs
- define `ENV` variable. See [Configuration](#configuration)

### Collecting information

#### Docker inspect

Once in 5 minutes `docker inspect` is executed for all containers (running and
not running). Data is getting recorded in JSON format. See [docker inspect](https://docs.docker.com/engine/reference/commandline/inspect/).

#### Docker stats

Once in 5 seconds `docker stats` is executed for all running containers.
Data is getting recorded in CSV format with fields `container_id`,
`cpu_percent`, `mem_usage`, `mem_limit`, `mem_percent`, `net_input`,
`net_output`. See [docker stats](https://docs.docker.com/engine/reference/commandline/stats/).

#### Docker top

Once in 5 minutes `docker top` is executed for all running containers.
Data is getting recorded in CSV format with fields `time`, `container_id`,
`pid`, `ppid`, `pgid`, `pcpu`, `vsz`, `nice`, `etime`, `time`, `tty`, `ruser`,
`user`, `rgroup`, `group`, `comm`, `args`. See `man ps` for information
about fields, and [docker top](https://docs.docker.com/engine/reference/commandline/top/).

#### Docker events

All events from `docker events` are streamed. See [docker events](https://docs.docker.com/engine/reference/commandline/events/)
for more details.

## Version

- Docker version: `18.09.3`
- Splunk Universal Forwarder: `7.2.4`

## Installation

You should get `splunkclouduf.spl` from you Splunk installation:
1. Click `App: Search and Reporting`
2. Choose `Universal Forwarder`
3. Click `Download Universal Forwarder Credentials` and 
save it to the dockerfile directory

Build the image locally.

```bash
git clone https://github.com/kashtan404/splunk-forwarder.git
cd splunk-forwarder
docker build --tag="$USER/splunk-forwarder" .
```

Push to your private repo, if you need.

## Start

To start the container

```bash
docker run --name splunk_forwarder \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v /var/log:/var/log \
    -v /etc/hostname:/etc/hostname:ro \
    -e "ENV=stg" \
    -d $USER/splunk-forwarder
```

## Configuration

- `ENV` - specify the environment for the Splunk indices.

- Define your indices:
`<@index@>` will be replaced with `ENV` value, so make sure you wrote correct values 
```text
[monitor:///var/log/dmesg]
index = @index@_docker_node
sourcetype = dmesg
host = @hostname@
disabled = false

[script://$SPLUNK_HOME/bin/scripts/docker_inspect.sh]
index = @index@_docker_stats
interval = 300
sourcetype = DockerInspect
host = @hostname@
source = docker_inspect
```

Container configures by itself:
```bash
	if [ -z $ENV ]; then
	echo "'ENV' env variable is empty or undefined." >&2
	exit 1
	else
	sed -e "s/@index@/$ENV/" -i ${SPLUNK_HOME}/etc/system/local/inputs.conf
	fi
	sed -e "s/@hostname@/$(cat /etc/hostname)/" -i ${SPLUNK_HOME}/etc/system/local/inputs.conf
```

See [entrypoint.sh - start() section](https://github.com/kashatn404/splunk-forwarder/init/entrypoint.sh) for more details.

## Permissions

Make sure that you have right permissions for your `/var/run/docker.sock`.
Or you can always run container under `root` user.

## Dashboards

You could find 2 dashboards in `dashboards` directory:
- Docker - reflects CPU,Memory,Network,Block usage and last events per Docker node
- Docker container - reflects last docker events and top processes per container

If you use not the `*_docker_stats` name for docker stats indices, 
you should also rename index in the query of the first fieldset:
```xml
        <query>index=*_docker_stats |
              fields index |
              dedup index |
              table index |
              sort index</query>
```