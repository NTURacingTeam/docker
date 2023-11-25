#!/bin/bash
set -e

. /opt/ros/${ROS_DISTRO}/setup.bash
. /microros_ws/install/local_setup.bash

exec "$@"
