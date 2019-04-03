#!/bin/bash

DOCKER_BIN=/docker/docker
"$DOCKER_BIN" events | grep -v "container top"
