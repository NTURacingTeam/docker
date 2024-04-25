# image based on nturacing/nturt_ros host devel
FROM nturacing/nturt_ros:host-devel

# clone nturt_ros, nturt_test packages
# install dependencies and build ws
RUN apt-get update \
    && . /opt/ros/${ROS_DISTRO}/setup.sh \
    && cd ws && . install/setup.sh \
    && git clone --recurse-submodules https://github.com/NTURacingTeam/nturt_ros.git src/nturt_ros \
    && git clone --recurse-submodules https://github.com/NTURacingTeam/nturt_test.git src/nturt_test \
    && rosdep install --from-paths src --ignore-src -r -y  \
    && colcon build --symlink-install \
    && rm -rf /var/lib/apt/lists/*

# setup cmd
COPY ./cmd.sh /
CMD ["/cmd.sh"]
