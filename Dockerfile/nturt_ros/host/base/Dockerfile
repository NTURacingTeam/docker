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
    unzip \
    vim \
    wget \
    && rm -rf /var/lib/apt/lists/*

# install wiringPi
RUN git clone https://github.com/WiringPi/WiringPi.git \
    && cd WiringPi \
    && ./build \
    && cd .. \
    && rm -rf WiringPi
