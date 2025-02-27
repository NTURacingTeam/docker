# image based on ros iron desktop full
# for linux/amd64 platforms
FROM --platform=linux/amd64 osrf/ros:iron-desktop-full-jammy AS stage-amd64

# for linux/arm64 platforms
FROM --platform=linux/arm64 ros:iron-ros-base-jammy AS stage-arm64

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-desktop-full \
    && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH

# select final stage based on TARGETARCH ARG
FROM stage-${TARGETARCH} AS final

# install general packages
RUN apt-get update && apt-get install --no-install-recommends -y \
    bash-completion \
    ca-certificates \
    curl \
    htop \
    lsb-release \
    net-tools \
    python3-pip \
    tmux \
    udev \
    unzip \
    vim \
    wget \
    && rm -rf /var/lib/apt/lists/*

# install jetson gpio
# fake logname command to always return "root"
RUN echo "echo root" > /usr/bin/logname \
    && git clone https://github.com/pjueon/JetsonGPIO \
    && cd JetsonGPIO && mkdir build && cd build \
    && cmake .. -DBUILD_EXAMPLES=OFF \
    && cmake --build . --target install \
    && cd ../.. && rm -rf JetsonGPIO

# clone microros setup ros package
# install dependencies and build microros_ws
# setup microros setup
RUN apt-get update \
    && . /opt/ros/${ROS_DISTRO}/setup.sh \
    && mkdir -p microros_ws/src && cd microros_ws \
    && git clone -b ${ROS_DISTRO} --recurse-submodules https://github.com/micro-ROS/micro_ros_setup.git src/micro_ros_setup \
    && rosdep install --from-paths src --ignore-src -r -y \
    && colcon build && rm -rf log build src \
    && . install/local_setup.sh \
    && ros2 run micro_ros_setup create_agent_ws.sh \
    && ros2 run micro_ros_setup build_agent.sh \
    &&  rm -rf /var/lib/apt/lists/*

# setup entrypoint
COPY ./nturt_ros_entrypoint.sh /
ENTRYPOINT ["/nturt_ros_entrypoint.sh"]
CMD ["bash"]
