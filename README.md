# Readme for Docker Environment
## Before you start
Install docker on your computer, checkout [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

## Usage
### Initialize the environment
```bash=
./build_ros.sh
```
There will be two availible images for you to chooes form, i.e. host and rpi.

The difference between host and rpi is mainly on the ros version we installed. Basically host version will included some visual tools. 
In the future we plan to debug the machine via uuv_host container on our host while running uuv_rpi container on the raspberry pi.

There will be other option prompts for you to chooes when installing, please choose accroding to youur needs.

### What will be installed
The host image is based on Ubuntu 20.04 and has the following applications preinstalled:
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

There will also we python3 packages preinstalled:
- python3-pip (package configuration tool)
- python3-rosdep (ros)
- python3-rosinstall (ros)
- python3-rosinstall-generator (ros)
- python3-wstool (ros)

### ROS enviroment
There will be ros workspace directory preconfigured in `/home/ros/ws` and its subdirectory `src` mounted to the host as `./packages`.
> Note: If you successfuly pulled packages from NTURacing, they will appear here.

The general ros environment setup
```bash=
source /opt/ros/noetic/setup.bash
source /opt/ros/noetic/setup.bash
```
has already beign included in `.bashrc` file, so there is no need to source them everytime.
### Entering the container
```bash=
# on desktop(host)

# if your container is not running
./start_docker_host.sh run

# to get into shell
./start_docker_host.sh shell

# to stop the container running
./start_docker_host.sh stop


# on rpi

# if your container is not running
./start_docker_rpi.sh run

# to get into shell
./start_docker_rpi.sh shell

# to stop the container running
./start_docker_rpi.sh stop
```

### play with shell
```bash=
# default is bash
./start_docker_xxx.sh shell

# you can attach to any shell you like
./start_docker_xxx.sh shell [shell_name] # eg. ./start_docker_rpi.sh zsh

# you can also use tmux
./start_docker_xxx.sh shell tmux                        # start a tmux session
./start_docker_xxx.sh shell tmux a                      # attach to the default session
./start_docker_xxx.sh shell tmux a [session_name]       # attach to a specific session
./start_docker_xxx.sh shell tmux new [session_name]     # new a session with name
./start_docker_xxx.sh shell tmux kill [session_name]    # kill an existing session
```
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