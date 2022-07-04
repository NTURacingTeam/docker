#!/bin/bash
COLOR_REST='\e[0m'
HIGHLIGHT='\e[0;1m'
REVERSE='\e[0;7m'
COLOR_GREEN='\e[0;32m'
COLOR_RED='\e[1;31m'
# DIR=$(dirname $(readlink -f $0))

DOCKER_FILE=ros_uuv

if [ "$1" = "run" ]; then
    if [[ -n $(docker ps --all | grep "uuv_host") ]]; then
        docker start uuv_host
    #echo "$(id -u):$(id -g)"
    else
        echo "Starting"
        #echo "$(id -u):$(id -g)"
        ip=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')
        docker run -itd -u $(id -u):$(id -g) \
            --privileged \
            --env="QT_X11_NO_MITSHM=1" \
            --env="DISPLAY=$ip:0" \
            --volume="/dev:/dev:rw" \
            --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
            --volume="$(pwd)/packages:/home/ros/ws/src:rw" \
            --volume="$HOME/.Xauthority:/root/.Xauthority:rw" \
            --volume="/etc/localtime:/etc/localtime:ro" \
            --hostname uuv \
            --add-host uuv:127.0.1.1 \
            -p 8080:8080 \
            --name uuv_host \
            -u ros \
            ros_uuv_host
    fi
elif [ "$1" = "shell" ]; then
    if [[ -z $(docker ps | grep "uuv_host") ]]; then
        echo "Your container is not running, please run it first"
    elif [ -z "$2" ]; then
        docker exec -it uuv_host bash
    elif [ "$2" = "tmux" ]; then
        if [ -z "$3" ]; then
            docker exec -it uuv_host tmux -u
        elif [ "$3" = "a" ]; then
            if [ -z "$4" ]; then
                docker exec -it uuv_host tmux -u a
            else
                docker exec -it uuv_host tmux -u a -t $4
            fi
        elif [ "$3" = "new" ]; then
            docker exec -it uuv_host tmux -u new -s $4
        elif [ "$3" = "kill" ]; then
            if [ -z "$4" ]; then
                echo -e "${COLOR_RED}Error: ${HIGHLIGHT}please examine the session to kill\n${COLOR_REST}use ${REVERSE}./start_docker_rpi.sh shell tmux ls${COLOR_REST} to see active sessions"
                exit 1
            elif [ -z $(docker exec -it uuv_host tmux ls | grep $4:) ]; then
                echo -e "${COLOR_RED}Error: ${HIGHLIGHT}cannot find the session to kill\n${COLOR_REST}use ${REVERSE}./start_docker_rpi.sh shell tmux ls${COLOR_REST} to see active sessions"
                exit 1
            else
                docker exec -it uuv_host tmux -u kill-session -t $4
            fi
        elif [ "$3" = "ls" ]; then
            docker exec -it uuv_host tmux ls
        fi
    else
        docker exec -it uuv_host $2
    fi
elif [ "$1" = "stop" ]; then
    docker stop uuv_host
else
    echo -e "${COLOR_RED}Error: ${HIGHLIGHT}What do you want to do???"
    exit 1
fi
# docker start -i uuv_host
# export containerId=$(sudo docker ps -l -q)
