# image based on nturacing/nturt_ros rpi base
FROM nturacing/nturt_ros:rpi-base

# switch to root home directory
ENV USER root
WORKDIR /root

# ros setup
# prebuild ws once
RUN . /opt/ros/${ROS_DISTRO}/setup.sh \
    && mkdir -p ws/src && cd ws && colcon build --symlink-install

# modify .bashrc for root
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc \
    && echo "source /usr/share/colcon_cd/function/colcon_cd.sh" >> ~/.bashrc \
    && echo "export _colcon_cd_root=/opt/ros/${ROS_DISTRO}/" >> ~/.bashrc \
    && echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> ~/.bashrc \
    && echo "source ~/ws/install/local_setup.bash" >> ~/.bashrc

# setup entrypoint
COPY ./nturt_ros_entrypoint.sh /
ENTRYPOINT ["/nturt_ros_entrypoint.sh"]
CMD ["bash"]
