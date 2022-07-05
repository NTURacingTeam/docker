#!/bin/bash

# declare text styles
COLOR_REST='\e[0m'
HIGHLIGHT='\e[0;1m'
REVERSE='\e[0;7m'
COLOR_GREEN='\e[0;32m'
COLOR_RED='\e[1;31m'

# run/attach/stop container
# reading command with bash arguement support
if [[ -z $1 ]]; then
    echo -e "What do you want to do?\n1. run container (run)\n2. attach into container shell (shell)\n3. stop the container(stop)"
    read -p "(run/shell/stop): " COMMAND
else
    COMMAND=$1
fi
while true; do
    if [ ${COMMAND} == "run" ]; then
        if ! [[ -e "container_name.txt" ]]; then
            echo -e "${COLOR_RED}Error: ${HIGHLIGHT}No container has being built by the provided script, please build one first${COLOR_REST}"
        elif [[ -z $(sed -n '2,$p' container_name.txt) ]]; then
            echo -e "${COLOR_RED}Error: ${HIGHLIGHT}Containers built by the provided script were all removed, please build one first${COLOR_REST}"
        else
            # reading name with bash arguement support
            if [[ -z $2 ]]; then
                echo "The following are the containers you can run:"
                sed -n '2,$p' container_name.txt
                read -p "What container do you want to run? " NAME
            else
                NAME=$2
            fi
            if [[ -z $(sed -n '2,$p' container_name.txt | grep -w ${NAME}) ]]; then
                echo -e "${COLOR_RED}Error: ${HIGHLIGHT}The container does not exist or is not built using the provided script, \
please build one first${COLOR_REST}"
            elif [[ -n $(docker container list | grep -w ${NAME}) ]]; then
                echo "The container is already running"
            else
                echo "Starting ${NAME}"
                docker start ${NAME}
            fi
        fi
        break
    elif [ ${COMMAND} == "shell" ]; then
        if ! [[ -e "container_name.txt" ]]; then
            echo -e "${COLOR_RED}Error: ${HIGHLIGHT}No container has being built by the provided script, please build one first${COLOR_REST}"
        elif [[ -z $(sed -n '2,$p' container_name.txt) ]]; then
            echo -e "${COLOR_RED}Error: ${HIGHLIGHT}Containers built by the provided script were all removed, please build one first${COLOR_REST}"
        else
            # reading name with bash arguement support
            if [[ -z $2 ]]; then
                echo "The following are the containers you can attach into shell:"
                sed -n '2,$p' container_name.txt
                read -p "What container do you want to attach into shell? " NAME
            else
                NAME=$2
            fi
            if [[ -z $(sed -n '2,$p'  container_name.txt | grep -w ${NAME}) ]]; then
                echo -e "${COLOR_RED}Error: ${HIGHLIGHT}The container does not exist or is not built using the provided script, \
please build one first${COLOR_REST}"
            elif [[ -n $(docker container list | grep -w ${NAME}) ]]; then
                docker exec -it ${NAME} bash
            else
                echo "The contatiner is not running, starting ${NAME}"
                docker start ${NAME}
                docker exec -it ${NAME} bash
            fi
        fi
        break
    elif [ ${COMMAND} == "stop" ]; then
        if [[ -z $(docker container list | sed -n '2,$p') ]]; then
            echo -e "${COLOR_RED}Error: ${HIGHLIGHT}There is currently no container running${COLOR_REST}"
        else
            # reading name with bash arguement support
            if [[ -z $2 ]]; then
                echo "The following is the containers that is currently running:"
                docker container list
                read -p "Which one do you want to stop? " NAME
            else
                NAME=$2
            fi
            while [[ -z $(docker container list | grep -w ${NAME}) ]]; do
                echo -e "${COLOR_RED}Error: ${HIGHLIGHT}The container does not exist or is not running${COLOR_REST}"
                read -p "Please choose a running container to stop: " NAME
            done
            docker stop ${NAME}
        fi
        break
    else
        echo -e "${COLOR_RED}Error: ${HIGHLIGHT}Unknown option${COLOR_REST}"
        read -p "Please enter correct command. (run/shell/stop): " COMMAND
    fi
done
