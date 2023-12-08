# image based on ros2 iron base
FROM ros:iron-ros-base-jammy

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
