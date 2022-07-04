#!/bin/bash
COLOR_REST='\e[0m'
HIGHLIGHT='\e[0;1m'
REVERSE='\e[0;7m'
COLOR_GREEN='\e[0;32m'
COLOR_RED='\e[1;31m'
# DIR=$(dirname $(readlink -f $0))

DOCKER_FILE=ros_uuv

if [ "$1" = "run" ]; then
    if [[ -n $(docker ps --all | grep "uuv_rpi") ]]; then
        docker start uuv_rpi
    #echo "$(id -u):$(id -g)"
    else
        echo "Starting"
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
            --name uuv_rpi \
            -u ros \
            ros_uuv_rpi
    fi
elif [ "$1" = "shell" ]; then
    if [[ -z $(docker ps | grep "uuv_rpi") ]]; then
        echo "Your container is not running, please run it first"
    elif [ -z "$2" ]; then
        docker exec -it uuv_rpi bash
    elif [ "$2" = "tmux" ]; then
        if [ -z "$3" ]; then
            docker exec -it uuv_rpi tmux -u
        elif [ "$3" = "a" ]; then
            if [ -z "$4" ]; then
                docker exec -it uuv_rpi tmux -u a
            else
                docker exec -it uuv_rpi tmux -u a -t $4
            fi
        elif [ "$3" = "new" ]; then
            docker exec -it uuv_rpi tmux -u new -s $4
        elif [ "$3" = "kill" ]; then
            if [ -z "$4" ]; then
                echo -e "${COLOR_RED}Error: ${HIGHLIGHT}please examine the session to kill\n${COLOR_REST}use ${REVERSE}./start_docker_rpi.sh shell tmux ls${COLOR_REST} to see active sessions"
                exit 1
            elif [ -z $(docker exec -it uuv_rpi tmux ls | grep $4:) ]; then
                echo -e "${COLOR_RED}Error: ${HIGHLIGHT}cannot find the session to kill\n${COLOR_REST}use ${REVERSE}./start_docker_rpi.sh shell tmux ls${COLOR_REST} to see active sessions"
                exit 1
            else
                docker exec -it uuv_rpi tmux -u kill-session -t $4
            fi
        elif [ "$3" = "ls" ]; then
            docker exec -it uuv_rpi tmux ls
        fi
    else
        docker exec -it uuv_rpi $2
    fi
elif [ "$1" = "stop" ]; then
    docker stop uuv_rpi
else
    echo -e "${COLOR_RED}Error: ${HIGHLIGHT}What do you want to do???"
    exit 1
fi
# docker start -i uuv_rpi
# export containerId=$(sudo docker ps -l -q)
