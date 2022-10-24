# National Taiwan University Racing Team Software Development Log
###### tags: `development_log` `NTURT`
##### Group: electrical system group
##### Person in charge: 羅紀翔
##### Authors: 羅紀翔 詹侑昕
##### Subsystem: docker
##### Subsystem number: DO1
##### Software name: docker_virtual_environment
##### Repository: [github](https://github.com/NTURacingTeam/docker)
##### Started designing date: 2022/7/28
##### Current version: 2.7
##### Last modified date: 2022/10/21
---
## Engineering goal:

Virtual environment are commanly used in order to avoid unnecessary environment setups as a result of different computers with different software installed. Here docker is adoped as a comprehensive virtual environment that is applicable for every software.

## Program structure:

In order to simplify the use of docker, the program uses bash script with prompt to ask user what do they want to do, and then execute docker command accrodingly. For more information for how to use, please refer to `Usage` section in `README.md`.

The software also provides custom dockerfile in `Dockerfile` to build custom images that fit our needs. For more information for what is installed, please refer to `Image environment` section in `README.md`.

## Included libraries:

[matlab package manager](https://github.com/mathworks-ref-arch/matlab-dockerfile)

## Testing environment:

- bash 5.0.17(1)-release (x86_64-pc-linux-gnu)
- docker 20.10.17, build 100c701

##### Testing hardware:

- asus tuf gaming a15 FA506II-0031A 4800H
- raspberry pi 3B+

##### Operating system:

- ubuntu 20.04
- raspbian 32-bit

##### Compiler(intepreter) version:

- N/A

---

## Change date of 2.10: 

## Changes in 2.10:

- Install `wiringPi` using github repository instead of apt in images `ros_matlab`, `ros_host`, `ros_rpi`.

## Change reasons of 2.10:

- To prevent wierd problems.

## Change date of 2.9: 2022/10/22

## Changes in 2.9:

- Change the base image `fun_time_with_arthur` into a nvidia/cuda:11.7.0-base-ubuntu22.04
- Swap ros1 in `fun_time_with_arthur` to ros2
- Add gpd, gpsd-clients, ros-noetic-gps-common, ros-noetic-gpsd-client and python package gps3 to `ros_rpi`, `ros_host`, `ros_matlab`
- Add matlab product `Control_System_Toolbox` to `ros_matlab`
- Add matlab product `Symbolic_Math_Toolbox` to `ros_matlab`
- Removed matlab product `DSP_System_Toolbox`, `Signal_Processing_Toolbox` from `ros_matlab`
- Add `ros-humble-gazebo-ros-pkgs` to `fun_time_with_arthur` and `ros2_host`
- Add `libyaml-cpp-dev` to `ros_rpi`
- Add `ros-humble-ros2-controller` to `fun_time_with_arthur`

## Change reasons of 2.9:

- In order to use ros2 in `fun_time_with_arthur`
- In order to use ros2 in `fun_time_with_arthur`
- In order to use gps
- In order to use transfer fuction
- In order to solve differential equations
- The product is no longer necessary
- In order to use gazebo with ros2
- In order to use yaml in cpp
- Inn order to use ros2 controllers

## Testing result of 2.9:

### Libraries compatibility

Most of them work great, some of them need some twicks but overall fine.

## Todos in 2.9:

---

## Change date of 2.8: 2022/9/5

## Changes in 2.8:

- Add DSP_System_Toolbox and Signal_Processing_Toolbox to matlab
- Add new image `ros2_host`

## Change reasons of 2.8:

- In order to split a matrix into vectors
- In order to test ros2 functionality

## Testing result of 2.8:

### ros2_host

Built successfully

## Todos in 2.8:

---
## Change date of 2.7: 2022/8/27

## Changes in 2.7:

- Make creating a container from `ros_rpi` image to have
  - A not separated network with the host
  - Root as the default user
- Added wiringpi, python3-serial to `ros_rpi` image

## Change reasons of 2.7:

- In order to hve the same functionality as on the host
- Packages that will be used for can

## Testing result of 2.7:
### Launch ros on rpi

All functionality are as aspected as running on the host

## Todos in 2.7:

---

## Change date of 2.6: 2022/8/15

## Changes in 2.6

- Add matlab product: Simescape Electrical to ros_matlab
- Changed the default user for ros_rpi image sto root

## Change reasons of 2.6:

- Using Simescape Electrical for motor model
- To avoid wierd permission problem when accessing /dev

## Testing result of 2.6:
### Launch ros from host by

```bash=Changes in 
docker -d exec ros bash -c "source /opt/ros/noetic/setup.bash && source /root/ws/devel/setup.bash && roslaunch /root/ws/src/nturt_ros.launch"
```
ros launched successfully

## Todos in 2.6:

---

## Change date of 2.5: 2022/8/12

## Changes in 2.5:

- Minor bug fix
  - fix image build and container access to can hat problem on rpi 
- Add packages need for can to ros_rpi
- Add some library for openAI gym and pytorch to fun_time_with_arthur
- Add some matlab product to ros_matlab


## Change reasons of 2.5:
- Some problem when using can hat on docker

## Testing result of 2.5:
### Building `ros_rpi` on rpi

Built successfully

### Creating contianer on rpi for can hat usage

Can hat worked successfully

## Todos in 2.5:

---

## Change date of 2.4: 2022/8/5

## Changes in 2.4:

- Minor bug fix
  - mkdir the package directory for the container before creating a container
- Add `Simscape_Driveline` package to matlab

## Change reasons of 2.4:

- if docker bind-mount without the directory alreadly exist, the directory wiil be created under root permission
- Using imscape_Driveline for vehicle dynamics

## Testing result of 2.4:
### Creating a continer without the package directory exist

created successfully without permission problem

## Todos in 2.4:

- Not tested on raspberry pi yet

---

## Change date of 2.3: 2022/8/4

## Changes in 2.3:

- Minor bug fix
  - Using older version of matlab in prevention of glibc version problem
- Add `Vehicle_Dynamics_Blockset` package to matlab

## Change reasons of 2.3:

- Crash when activating simulink as a result of too old version of glibc of ubuntu20.04
- Using Vehicle_Dynamics_Blockset for vehicle dynamics

## Testing result of 2.3:
### Activating simulink

successfully

## Todos in 2.3:

- Not tested on raspberry pi yet

---

## Change date of 2.2: 2022/8/4

## Changes in 2.2:

- Minor bug fix
  - Give /usr/share/matlab/licenses permission for everone as matlab is installed in root user
- Make the script useable for hosts without nvidia docker support

## Change reasons of 2.2:

- Matlab have to have permission to /usr/share/matlab/licenses in order to activate
- The script was original only usable for hosts with nvidia docker support

## Testing result of 2.2:
### ros_matlab

Permission problem resolved successfully

### Create container with nvidia docker support

run

```bash=
./start_container create ros roe_matlab
```

with nvidia docker support
created successfully

### Create container without nvidia docker support

run

```bash=
./start_container create ros roe_matlab
```

without nvidia dockChanges in er support
created successfully

## Todos in 2.2:

- Not tested on raspberry pi yet

---

## Change date of 2.1: 2022/8/4

## Changes in 2.1:

- Minor bug fix
  - Reverse the order of sourcing ros and ros workspace in .bashrc
- Reformat 軟體日誌 to newer version

## Change reasons of 2.1:

- Sourcing ros workapsce before sourcing ros have no effect

## Testing result of 2.1:
### ros_matlab

Auto-sourcing ~/ws/devel/setup.bash Successfully

### fun_time_with_arthur

Auto-sourcing ~/ws/devel/setup.bash Successfully

## Todos in 2.1:

- Currently creating a container always uses some specific configuration (always using gpu), will be changed in the next version
- Not tested on raspberry pi yet

---

## Change date of 2.0: 2022/7/30

## Changes in 2.0:

- Added three other dockerfiles for different needs, including
  - ros_host: image with ros for desktop use
  - ros_matlab: image with ros and matlabfor desktop use
  - ros_rpi: image with ros for use on raspberry pi
- Rewrite dockerfiles to shorten the build stepts

## Change reasons of 2.0:

- Add other images for different needs, especially ros_matlab for future developments
- Rewrite dockerfiles for better performances, please checkout [Better practice for writting dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

## Testing result of 2.0:
### Test building image

run

```bash=
./build_image fun_time_with_arthur
./build_image ros_matlab
```

Built successfully

## Todos in 2.0:

- Currently creating a container always uses some specific configuration
- Not tested on raspberry pi yet

---

## Testing result of 1.0:
### Test building image

run

```bash=
./build_image fun_time_with_arthur
```

#### Without an image with same name and tag `latest`

Built successfully

#### With an image with same name and tag `latest`

Built successfully

### Test create/run/shell/stop container

run

```bash=
./start_container COMMAND CONTAINER_NAME [IMAGE_NAMME]
```

All worked successfully

## Todos in 1.0:

- Currently creating a container always uses some specific configuration, which should be change to be configuratable.
- The `ros_uuv_rpi` image should be updated, tested and documented in `README.md`.
- Should add an image with only desktop ros.
