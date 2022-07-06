# Readme for Docker Environment
## Before you start
Install docker on your computer, checkout [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

## Usage
### Initialize the environment
```bash=
./build_ros.sh
```
There will be two availible images for you to chooes form, host and rpi (which will create docker image ros_uuv_host and ros_uuv_rpi, respectively).

The difference between host and rpi is mainly on the ros version we installed. Basically host version will included some visual tools. 
In the future we plan to debug the machine via uuv_host container on our host while running uuv_rpi container on the raspberry pi.

This script supports custom naming of your containers.

There will be other option prompts for you to chooes when installing, please choose accroding to youur needs.

> Note: In order to connect to the container by interent, port `8080` with host ip `127.0.1.1` is designated for the container, so you can only run a container at a time that was built by `build_ros.sh` script.

#### What will be installed
The base image is 11.7.0-devel-ubuntu20.04, which is based on ubuntu 20.04 with full Nvida cuda support and has the following applications preinstalled:
- For managing apt keyrings and installing other packages
    - ca-certificates
    - wget
    - curl
    - gnupg2
- Compiler
    - build-essential
- ROS
    - ros-noetic-desktop-full (ros)
    - ros-noetic-teleop-twist-keyboard (ros keyboard control)
    - ros-noetic-rqt-multiplot (ros ploting tool)
    - ros-noetic-socketcan-bridge (can message converter)
- Mujoco
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

There will also be python3 packages preinstalled:
- python3-pip (package configuration tool)
- python3-rosdep (ros)
- python3-rosinstall (ros)
- python3-rosinstall-generator (ros)
- python3-wstool (ros)
- mujoco-py (bindings for mujoco in python)

#### ROS enviroment
There will be ros workspace directory preconfigured in `/home/ros/ws` and its subdirectory `src` mounted to the host as `./packages/${container_name}`.

The workspace `~/ws` has already been prebuild once, so there will also be `build` and `devel` directory beside the `src`.
> Note: If you successfuly pulled packages from NTURacingTeam, they will appear here.

The general ros environment setup
```bash=
source /opt/ros/noetic/setup.bash
source ~/ws/devel/setup.bash
```
has already beign included in `.bashrc` file, so there is no need to source them everytime.
### Entering the container
While the `build_ros.sh` script is specificly designed for building a container with features listed above, the `start_docker.sh` script provided universal run/shell/stop utilities, so it may also used for controlling other containers that were not built by `build_ros.sh` script.
```bash=
./start_docker.sh
```
you will be prompted by different commands to control the containers

The script also support bash arguements as a short hand
```bash=
./start_docker.sh COMMAND CONTAINER_NAME
```
where COMMAND can be run/shell/stop for your needs.

## Known Issues
1. We have some issues when building on WSL. Such as using byobu and visualize environments.
2. Not tested on rpi yet.
3. If it is on **Debian**, follow the steps to solve libseccomp:
```bash=
#download from https://packages.debian.org/sid/libseccomp2, for example: 
wget http://ftp.tw.debian.org/debian/pool/main/libs/libseccomp/libseccomp2_2.5.3-2_armhf.deb
sudo dpkg -i libseccomp2_2.5.3-2_armhf.deb
ref: https://askubuntu.com/questions/1263284/apt-update-throws-signature-error-in-ubuntu-20-04-container-on-arm
```