# image based on nturacing/nturt_ros host base
FROM nturacing/nturt_ros:host-base

# adding user "docker" and add it to sudo group
# password "docker" for root and user "docker"
RUN useradd --create-home --shell /bin/bash docker \
    && usermod -aG sudo docker \
    && echo "docker\ndocker" | passwd \
    && echo "docker\ndocker" | passwd docker

# change to user "docker" and change to home directory
USER docker
ENV USER docker
WORKDIR /home/docker

# ros setup
# update rosdep for user "docker"
# prebuild ws once
RUN . /opt/ros/${ROS_DISTRO}/setup.sh \
    && rosdep update --rosdistro ${ROS_DISTRO} \
    && mkdir -p ws/src && cd ws && colcon build --symlink-install

# copy and modify .bashrc for user "docker"
RUN cp /etc/skel/.bashrc /home/docker \
    && echo "export PATH=:${PATH}:~/.local/bin" >> ~/.bashrc \
    && echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc \
    && echo "source /usr/share/colcon_cd/function/colcon_cd.sh" >> ~/.bashrc \
    && echo "export _colcon_cd_root=/opt/ros/${ROS_DISTRO}/" >> ~/.bashrc \
    && echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> ~/.bashrc \
    && echo "source ~/ws/install/local_setup.bash" >> ~/.bashrc

# setup entrypoint
COPY ./nturt_ros_entrypoint.sh /
ENTRYPOINT ["/nturt_ros_entrypoint.sh"]
CMD ["bash"]
