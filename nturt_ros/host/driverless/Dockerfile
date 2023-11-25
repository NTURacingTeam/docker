# image based on nturacing/nturt_ros host devel
FROM nturacing/nturt_ros:host-devel

# change to root for elevated privileges
USER root
WORKDIR /

# install general packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    libvulkan1 \
    xorg-dev \
    && rm -rf /var/lib/apt/lists/*

# install jetson gpio
# fake logname command to always return "docker"
RUN echo "echo docker" > /usr/bin/logname \
    && git clone https://github.com/pjueon/JetsonGPIO \
    && cd JetsonGPIO && mkdir build && cd build \
    && cmake .. -DBUILD_EXAMPLES=OFF \
    && cmake --build . --target install \
    && cd ../.. && rm -rf JetsonGPIO

# install f1tenth gym
RUN git clone https://github.com/f1tenth/f1tenth_gym \
    && cd f1tenth_gym && pip3 install -e .

# clone FSDS ros package and setup
# install dependencies and build sim_ws
RUN apt-get update \
    && . /opt/ros/${ROS_DISTRO}/setup.sh \
    && mkdir -p sim_ws/src && cd sim_ws \
    && git clone --recurse-submodules https://github.com/NTURacingTeam/FSDS.git src/FSDS && ./src/FSDS/AirSim/setup.sh \
    && rosdep install --from-paths src --ignore-src -r -y \
    && colcon build && rm -rf log build src \
    && rm -rf /var/lib/apt/lists/*

# change to user "docker"
USER docker
WORKDIR /home/docker

# install fsds binary
RUN wget https://github.com/FS-Driverless/Formula-Student-Driverless-Simulator/releases/download/v2.2.0/fsds-v2.2.0-linux.zip \
    && unzip fsds-v2.2.0-linux.zip -d Formula-Student-Driverless-Simulator && rm fsds-v2.2.0-linux.zip

# modify .bashrc for user "docker"
RUN echo "source /sim_ws/install/local_setup.bash" >> ~/.bashrc

# setup entrypoint
COPY ./nturt_ros_entrypoint.sh /
ENTRYPOINT ["/nturt_ros_entrypoint.sh"]
CMD ["bash"]
