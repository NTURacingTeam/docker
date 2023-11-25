# image based on nturt_ros rpi base
FROM nturt_ros/ros:rpi-base

# switch to root home directory
USER root
ENV USER root
WORKDIR /root

# prebuild ws once, using bash warpper for avoiding wierd problems
RUN bash -c 'source /opt/ros/${ROS_DISTRO}/setup.bash && mkdir -p ws/src && cd ws && colcon build --symlink-install'

# modify .bashrc for root
RUN echo 'export PATH=:${PATH}:~/.local/bin' >> ~/.bashrc \
    && echo 'source /opt/ros/${ROS_DISTRO}/setup.bash' >> ~/.bashrc \
    && echo 'source /usr/share/colcon_cd/function/colcon_cd.sh' >> ~/.bashrc \
    && echo 'export _colcon_cd_root=/opt/ros/${ROS_DISTRO}/' >> ~/.bashrc \
    && echo 'source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash' >> ~/.bashrc \
    && echo 'source ~/ws/install/setup.bash' >> ~/.bashrc
