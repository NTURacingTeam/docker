# image based on nturacing/nturt_ros rpi devel
FROM nturacing/nturt_ros:rpi-devel

# clone nturt_ros ros package
# install dependencies and build ws
RUN apt-get update \
    && . /opt/ros/${ROS_DISTRO}/setup.sh \
    && cd ws && source install/setup.sh \
    && git clone --recurse-submodules https://github.com/NTURacingTeam/nturt_ros.git src/nturt_ros \
    && rosdep install --from-paths src --ignore-src -r -y  \
    && colcon build --symlink-install \
    && rm -rf /var/lib/apt/lists/*

CMD ["ros2", "launch", "nturt_rpi_deployer nturt_ros.launch.py"]
