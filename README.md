# Docker Virtual Environment

## Introduction

Virtual environment are commanly used in order to avoid unnecessary environment setups as a result of different computers with different software installed. Here docker is adoped as a comprehensive virtual environment that is applicable for every software.

We provide custom images ([Dockerfile](Dockerfile)) and runtime configs ([docker-compose.yaml](docker-compose)) for using ROS on desktop computers or RPis, jetsons, etc. And a handy command line tool to control these virtual environment.

## Before You Start

Install docker engine on your computer, please checkout [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/). Or simply run:

```bash=
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

to install docker engine.

**Note that installing Docker Desktop would launch the containers on QEMU virtualization, which would slow done the whole process. Make sure you Don't download anything about Docker Desktop.**

## Quick Start

1. Clone this repo to your computer:

    ```bash=
    git clone https://github.com/NTURacingTeam/docker.git
    ```
2. Install the command line tool:

    ```bash=
    ./install.sh
    ```
3. Create a container:

    ```bash=
    nturt_docker container create CONTAINER_NAME nturt_ros:host-devel host
    ```
4. Access the shell of the container:

    ```bash=
    nturt_docker container shell CONTAINER_NAME
    ```

Note: replace `CONTAINER_NAME` with the name of the container you want to use.

## Images

This repo provides different images for different purposes, distinguished by image names and tags in `name`:`target`-`distro` format, where `target` is the platform for the image and `distro` is different usage of the image.

### Provided Images

Images are built from [Dockerfile](Dockerfile) with following directory structure:

```
Dockerfile
└── image_name
    └── target
        └── distro
            ├── Dockerfile
            └── ...
```

The following images are provided:

- nturt_ros
  - host
    - base
    - devel
    - driverless
  - jetson
    - base
    - deploy
    - devel
  - rpi
    - base
    - deploy
    - devel

All images are built and published to [Docker Hub](https://hub.docker.com/r/nturacing/nturt_ros) so that you can pull them directly without building them first.

## Runtime Configs

Aside from images, docker also needs runtime configs for hardware, network, etc. to launch containers.

Docker compose is used to manage the runtime configs of containers. The runtime configs are defined in [docker-compose](docker-compose) with following directory structure:

```
docker-compose
└── mode
    └── docker-compose.yaml
```

The following modes are provided:

- host: for running containers on host computer
- host-nvidia: host mode with nvidia GPU support
- rpi: for running containers on Raspberry Pi as root user

## Command Line Tool

A command line tool `nturt_docker` is provided to control the virtual environment.

### Installation

To use the command line tool globally with shell completion, run:

```bash=
./install.sh
```

### Usage

The command line tool is used as:

```bash=
nturt_docker COMMAND [OPTIONS]
```

Use `--help` for all commands and options.

## Environment Setup

Some setup are required in order for the containers to run as intended.

### Bind Mount

Bind mount is a way to mount a directory from host to container. It is useful when you want to share files between host and container. For example, you can mount your workspace directory to the container, so that you can edit your code on host and run it on container.

A ROS workspace is preconfigured in `~/ws` and its subdirectory `src` mounted to the host at `path/to/this/repo/packages/CONTAINER_NAME`.

### Hardware Management

Usually, docker containers are not allowed to access hardware devices. But we can use `--privileged` flag and bind mount `/dev:/dev` to allow containers to access all host hardware. This is not recommended, but it is the easiest way to access hardware in containers.

### Networking

By default, containers are isolated from host network. We can use `--network host` flag to allow containers to access host network. This is not recommended, but it is the easiest way to access host network in containers.

### Support for Nvidia GPU in Docker

Docker containers may access nvidia GPU but it requires special setup, checkout how to setup nvidia docker support: [How to Use an NVIDIA GPU with Docker Containers](https://www.howtogeek.com/devops/how-to-use-an-nvidia-gpu-with-docker-containers/).

Containers can access nvidia GPU by using `host-nvidia` mode when creating a container as:

```bash=
nturt_docker container create CONTAINER_NAME IMAGE host-nvidia
```

### ROS

The usual ROS environment setup as mentioned in [Configuring ROS2 Environment](https://docs.ros.org/en/rolling/Tutorials/Beginner-CLI-Tools/Configuring-ROS2-Environment.html):

```bash=
source /opt/ros/${ROS_DISTRO}/setup.bash
source ~/ws/install/setup.bash
```

has already being included in `~/.bashrc` file for all `devel` distros of `nturt_ros` image, so there is no need to source them everytime.
