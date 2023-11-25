#!/bin/bash
set -e

. /opt/ros/${ROS_DISTRO}/setup.bash
. /home/docker/ws/install/local_setup.bash

exec "$@"
