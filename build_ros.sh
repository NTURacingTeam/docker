#!/bin/bash

# declare text styles
COLOR_REST='\e[0m'
HIGHLIGHT='\e[0;1m'
REVERSE='\e[0;7m'
COLOR_GREEN='\e[0;32m'
COLOR_RED='\e[1;31m'

# add display host
if [ $(uname) == "Linux" ]; then
    xhost local:root
    xhost +local:root
fi

# build docker image
# container name
read -p "What name do you want to name the container? " NAME
while [[ -n $(docker container list --all | grep -w ${NAME}) ]]; do
    echo -e "${COLOR_RED}Error: ${HIGHLIGHT}The image name has already taken${COLOR_REST}"
    read -p "Please choose another name: " NAME
done

# image type
read -p "Which image do you want to build? (host/rpi):" TASK
while [[ ${TASK} != "host" && ${TASK} != "rpi" ]]; do
    echo -e "${COLOR_RED}Error: ${HIGHLIGHT}Unknown image type${COLOR_REST}"
    read -p "Please enter correct image type. (host/rpi):" TASK
done

# build wiith or without cache
read -p "Do you want to build with cache? (y/n):" WITH_CACHE
while true; do
    if [[ ${WITH_CACHE} == "y" || ${WITH_CACHE} == "yes" ]]; then
        echo "Going to build ${TASK} with cache"
        if [ ${TASK} == "host" ]; then
            docker build -t ros_uuv_host -f ./Dockerfile/ros_uuv_host .
        else
            docker build -t ros_uuv_rpi -f ./Dockerfile/ros_uuv_rpi .
        fi
        break
    elif [[ ${WITH_CACHE} == "n" || ${WITH_CACHE} == "no" ]] ; then
        echo "Going to build ${TASK} with no cache"
        if [ ${TASK} == "host" ]; then
            docker build -t ros_uuv_host -f ./Dockerfile/ros_uuv_host . --no-cache
        else
            docker build -t ros_uuv_rpi -f ./Dockerfile/ros_uuv_rpi . --no-cache
        fi
        break
    else
        echo -e "${COLOR_RED}Error: ${HIGHLIGHT}Unknown option${COLOR_REST}"
        read -p "Please enter correct option. (y/n): " WITH_CACHE
    fi
done

# pull NTURacingTeam git repositpry
mkdir -p packages/${NAME}
echo "Proceeding to pull git files from NTURacingTeam repository"
echo -e "${HIGHLIGHT}Note this is a private repository, and you need to have setup github ssh key to pull successfully${COLOR_REST}"
read -p "Do you want to proceed? (y/n):" TO_PULL
while true; do
    if [[ ${TO_PULL} == "y" || ${TO_PULL} == "yes" ]]; then
        cd packages/${NAME}
        if ! [[ -d "nturt_can_parser" ]]; then
            git clone git@github.com:NTURacingTeam/nturt_can_parser.git
            cd nturt_can_parser && git checkout dev_new_def && cd ..
        fi

        if ! [[ -d "nturt_sideslip_estimator" ]]; then
            git clone git@github.com:NTURacingTeam/nturt_sideslip_estimator.git
        fi

        if ! [[ -d "nturt_sideslip_estimator_msgs" ]]; then
            git clone git@github.com:NTURacingTeam/nturt_sideslip_estimator_msgs.git
        fi

        if ! [[ -d "nturt_sim" ]]; then
            git clone git@github.com:NTURacingTeam/nturt_sim.git
            cd nturt_sim && git checkout slip_ratio && cd .. # should be removed when back to master
        fi

        if ! [[ -d "nturt_torque_cmd" ]]; then
            git clone git@github.com:NTURacingTeam/nturt_torque_cmd.git
        fi
        cd .. && cd ..
        break
    elif [[ ${TO_PULL} == "n" || ${TO_PULL} == "no" ]]; then
        break
    else
        echo -e "${COLOR_RED}Error: ${HIGHLIGHT}Unknown option${COLOR_REST}"
        read -p "Please enter correct option. (y/n):" TO_PULL
    fi
done

# attach to the container
if [ "${TASK}" == "host" ]; then
    ip=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}') # don't know what this is
    docker run -itd -u $(id -u):$(id -g) \
        --privileged \
        --env="QT_X11_NO_MITSHM=1" \
        --env="DISPLAY=$ip:0" \
        --volume="/dev:/dev:rw" \
        --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
        --volume="$(pwd)/packages/${NAME}:/home/ros/ws/src:rw" \
        --volume="$HOME/.Xauthority:/root/.Xauthority:rw" \
        --volume="/etc/localtime:/etc/localtime:ro" \
        --hostname uuv \
        --add-host uuv:127.0.1.1 \
        -p 8080:8080 \
        --name ${NAME} \
        -u ros \
        ros_uuv_host
    # build ws with empty src
    docker exec -d ${NAME} bash -c "source /opt/ros/noetic/setup.bash && cd ws && catkin_make"
    # installing mujoco
    docker exec -d ${NAME} bash -c "wget https://github.com/deepmind/mujoco/releases/download/2.1.0/mujoco210-linux-x86_64.tar.gz"
    docker exec -d ${NAME} bash -c "tar -xvf mujoco210-linux-x86_64.tar.gz && rm mujoco210-linux-x86_64.tar.gz"
    docker exec -d ${NAME} bash -c "mkdir -p .mujoco/mujoco210 && mv mujoco210 .mujoco/mujoco210"
    docker exec -it ${NAME} bash
else
    ip=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}') # don't know what this is
    docker run -itd -u $(id -u):$(id -g) \
        --privileged \
        --network host \
        --env="DISPLAY" \
        --env="QT_X11_NO_MITSHM=1" \
        --volume="/dev:/dev:rw" \
        --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
        --volume="$(pwd)/uuv_ws:/home/ros:rw" \
        --hostname uuv \
        --add-host uuv:127.0.1.1 \
        --name ${NAME} \
        -u ros \
        ros_uuv_rpi
    # build ws with empty src
    docker exec -d ${NAME} bash -c "source /opt/ros/noetic/setup.bash && cd ws && catkin_make"
    docker exec -it ${NAME} bash
fi