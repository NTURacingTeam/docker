# Readme for Docker Environment

## Before you start

Install docker on your computer, checkout [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

## Usage

### Build an image

Build a docker image from directory `Dockerfile` by

```bash=
./build_image.sh
```

you will be prompted by different commands to build differernt images.

> Note: The image name will be the same as the `dockerfile`'s name.

If an existing image has the same name as the `dockerfile`'s name and the tag is `latest`, an option will prompt you to choose whether to change the existing image's tag to `older_versionX` and build the new image with tag `latest`.

The script also support bash arguements as a short hand

```bash=
./build_image.sh IMAGE_FILE REPLACE_OPTION
```

where `IMAGE_FILE` is the dockerfile name in directory `Dockerfile` and `REPLACE_OPTION`(y/n) for controlling whether to change the tag of an image with same name to older vison.

### What image to build

There are currently two images, for more information, please refer to `` in latter section.

### Create a container

This script supports custom naming of your containers.

There will be other option prompts for you to chooes when installing, please choose accroding to youur needs.
> Note: In order to connect to the container by interent, port `8080` with host ip `127.0.1.1` is designated for the container, so you can only run a container at a time that was created by `staert_docker.sh` script.

### Entering the container

While the `build_image.sh` script is specificly designed for building a container with features listed above, the `start_container.sh` script provided universal `create`/`run`/`shell`/`stop` utilities, so it may also used for controlling other containers that were not built by `build_image.sh` script.

```bash=
./start_container.sh
```

you will be prompted by different commands to control the containers

The script also support bash arguements as a short hand

```bash=
./start_container.sh COMMAND CONTAINER_NAME IMAGE_NAME
```

where `COMMAND` can be run/shell/stop for your needs, and `IMAGE_NAME` is for building container with specific image name.
> Note the password in the container for default user `docker` is `docker`.

## Image environment

The following is the description of the image environments.

### fun_time_with_arthur

The base image is 11.7.0-base-ubuntu20.04, which is based on ubuntu 20.04 with full Nvida cuda support and has the following applications preinstalled:

- For managing apt keyrings and installing other packages
  - ca-certificates
  - wget
  - curl
  - gnupg2
- Compiler
  - build-essential
- Command line utilities
  - bash-completion (for completing commands)
  - zsh (for completing commands)
  - byobu (terminal multiplexer)
  - tmux (terminal multiplexer)
- Other utilities
  - net-tools (network configuration tool)
  - iputils-ping (network configuration tool)
  - vim (command line text editing tool)
  - git (version control)
  - feh (image viewer)
- ROS
  - ros-noetic-desktop-full (ros)
  - ros-noetic-teleop-twist-keyboard (ros keyboard control)
  - ros-noetic-rqt-multiplot (ros ploting tool)
  - ros-noetic-socketcan-bridge (can message converter)
- Nvidia-cuda-toolkit (for using gpu)
- Mujoco (simulating environment for openAI-gym)

There will also be python3 packages preinstalled:

- python3-pip (package configuration tool)
- python3-rosdep (ros)
- python3-rosinstall (ros)
- python3-rosinstall-generator (ros)
- python3-wstool (ros)
- openAI-gym (learning environment manger)
- envpool (faster learning environment manger)
- mujoco-py (bindings for mujoco in python)
- pytorch (maching learning libary)

### ROS enviroment

There will be ros workspace directory preconfigured in `/home/ros/ws` and its subdirectory `src` mounted to the host as `./packages/${container_name}`.

The workspace `~/ws` has already been prebuild(catkin_make) once, so there will also be `build` and `devel` directory beside the `src`.

The general ros environment setup

```bash=
source /opt/ros/noetic/setup.bash
source ~/ws/devel/setup.bash
```

has already beign included in `~/.bashrc` file, so there is no need to source them everytime.

## Known Issues

1. We have some issues when building on WSL. Such as using byobu and visualize environments.
2. If it is on **Debian**, follow the steps to solve libseccomp:
  
    ```bash=
    #download from https://packages.debian.org/sid/libseccomp2, for example: 
    wget http://ftp.tw.debian.org/debian/pool/main/libs/libseccomp/libseccomp2_2.5.3-2_armhf.deb
    sudo dpkg -i libseccomp2_2.5.3-2_armhf.deb
    ref: https://askubuntu.com/questions/1263284/apt-update-throws-signature-error-in-ubuntu-20-04-container-on-arm
    ```
