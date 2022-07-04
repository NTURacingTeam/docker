#!/bin/bash

# declare taxt styles
COLOR_REST='\e[0m'
HIGHLIGHT='\e[0;1m'
REVERSE='\e[0;7m'
COLOR_GREEN='\e[0;32m'
COLOR_RED='\e[1;31m'

# add display host
if [ $(uname) = "Linux" ]; then
    xhost local:root
    xhost +local:root
fi

# build docker image
read -p "Which image do you want to build? (host/rpi):" TASK
while [[ "${TASK}" != "host" && "${TASK}" != "rpi" ]]; do
    echo -e "${COLOR_RED}Error: ${HIGHLIGHT}Unknown image type${COLOR_REST}"
    read -p "Please enter correct image type. (host/rpi):" TASK
done

read -p "Do you want to build with cache? (y/n):" WITH_CACHE
while true; do
    if [[ "${WITH_CACHE}" == "y" || "${WITH_CACHE}" == "yes" ]]; then
        echo "Going to build ${TASK} with cache"
        if [ "${TASK}" == "host" ]; then
            docker build -t ros_uuv_host -f ./Dockerfile/ros_uuv_host .
        else
            docker build -t ros_uuv_rpi -f ./Dockerfile/ros_uuv_rpi .
        fi
        break
    elif [[ "${WITH_CACHE}" == "n" || "${WITH_CACHE}" == "no" ]] ; then
        echo "Going to build ${TASK} with no cache"
        if [ "${TASK}" == "host" ]; then
            docker build -t ros_uuv_host -f ./Dockerfile/ros_uuv_host . --no-cache
        else
            docker build -t ros_uuv_rpi -f ./Dockerfile/ros_uuv_rpi . --no-cache
        fi
        break
    else
        echo -e "${COLOR_RED}Error: ${HIGHLIGHT}Unknown option${COLOR_REST}"
        read -p "Please enter correct option. (y/n):" WITH_CACHE
    fi
done

# pull nturt git down
mkdir packages
echo "Proceeding to pull git files from NTURacingTeam"
echo -e "${HIGHLIGHT}Note this is a private repository, and you need github ssh key to pull successfully${COLOR_REST}"
read -p "Do you want to proceed? (y/n):" TO_PULL
while true; do
    if [[ "${TO_PULL}" == "y" || "${TO_PULL}" == "yes" ]]; then
        cd packages
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
        cd ..
        break
    elif [[ "${TO_PULL}" == "n" || "${TO_PULL}" == "no" ]]; then
        break
    else
        echo -e "${COLOR_RED}Error: ${HIGHLIGHT}Unknown option${COLOR_REST}"
        read -p "Please enter correct option. (y/n):" TO_PULL
    fi
done 

# attach to the container
if [ "${TASK}" == "host" ]; then
    ./start_docker_host.sh run
    ./start_docker_host.sh shell
else
    ./start_docker_rpi.sh run
    ./start_docker_rpi.sh shell
fi
