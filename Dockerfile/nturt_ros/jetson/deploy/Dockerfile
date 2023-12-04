# image based on nturacing/nturt_ros jetson devel
FROM nturacing/nturt_ros:jetson-devel

# clone nturt_nms1 ros package
# install dependencies and build ws
RUN apt-get update \
    && . /opt/ros/${ROS_DISTRO}/setup.sh \
    && cd ws && source install/setup.sh \
    && git clone --recurse-submodules https://github.com/NTURacingTeam/nturt_nms1.git src/nturt_nms1 \
    && rosdep install --from-paths src --ignore-src -r -y  \
    && colcon build --symlink-install \
    && rm -rf /var/lib/apt/lists/*

CMD ["ros2", "launch", "nturt_nms1 nturt_nms1.launch.py"]
