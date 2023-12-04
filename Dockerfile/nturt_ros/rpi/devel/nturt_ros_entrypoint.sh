#!/bin/bash
set -e

. /opt/ros/${ROS_DISTRO}/setup.bash
. /root/ws/install/local_setup.bash

exec "$@"
