#!/bin/bash

# declare text styles
COLOR_REST='\e[0m'
HIGHLIGHT='\e[0;1m'
REVERSE='\e[0;7m'
COLOR_GREEN='\e[0;32m'
COLOR_RED='\e[1;31m'

# create/run/attach/stop container
# reading command with bash arguement support
if [[ -z $1 ]]; then
    echo "What do you want to do?"
    echo -e "\t1. create container (create)"
    echo -e "\t2. run container (run)"
    echo -e "\t3. attach into container shell (shell)"
    echo -e "\t4. stop the container (stop)"
    read -p "(create/run/shell/stop): " COMMAND
else
    COMMAND=$1
fi
while true; do
    if [ ${COMMAND} == "create" ]; then
        if [[ -z $(docker images | sed -n '2,$p') ]]; then
            echo -e "${COLOR_RED}Error: ${HIGHLIGHT}No docker image has been built, please build one first${COLOR_REST}"
        else
            # reading container name with bash arguemant support
            if [[ -z $2 ]]; then
                read -p "What name do you want to name the new container? " CONTAINER_NAME
            else
                CONTAINER_NAME=$2
            fi
            while [[ -n $(docker container list -a | sed -n '2,$p' | awk '{print $NF}' | grep -w ${CONTAINER_NAME}) ]]; do
                echo -e "${COLOR_RED}Error: ${HIGHLIGHT}The container name has already taken${COLOR_REST}"
                read -p "Please enter another name or empty to abort: " CONTAINER_NAME
                if [[ -z ${CONTAINER_NAME} ]]; then
                    echo "Abort"
                    exit 0
                fi
            done

            # reading image name with bash arguement support
            if [[ -z $3 ]]; then
                echo "The following are the docker images you can create your container from:"
                docker image list | sed -n '2,$p' | awk '{print $1}'
                read -p "What docker image do you want to create your container from? " IMAGE_NAME
            else
                IMAGE_NAME=$3
            fi
            while [[ -z $(docker images | sed -n '2,$p' | awk '{print $1}' | grep -w ${IMAGE_NAME}) ]]; do
                echo -e "${COLOR_RED}Error: ${HIGHLIGHT}The image does not exist, please build it first${COLOR_REST}"
                read -p "Please enter an existing image name or empty to abort: " IMAGE_NAME
                if [[ -z ${IMAGE_NAME} ]]; then
                    echo "Abort"
                    exit 0
                fi
            done

            # create and attach to the container
            # create directory if the directory dosen't exist yet
            if ! [[ -d packages/${CONTAINER_NAME} ]]; then
                mkdir -p packages/${CONTAINER_NAME}
            fi

            # if used in rpi
            if [[ ${IMAGE_NAME} == "ros_rpi" || ${IMAGE_NAME} == "ros2_rpi" ]]; then
                echo "Creating ${CONTAINER_NAME} with ${IMAGE_NAME} image using rpi configuration"
                docker run -itd \
                --privileged \
                --env="QT_X11_NO_MITSHM=1" \
                --volume="/dev:/dev:rw" \
                --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
                --volume="$(pwd)/packages/${CONTAINER_NAME}:/root/ws/src:rw" \
                --volume="${HOME}/.Xauthority:/root/.Xauthority:rw" \
                --volume="/etc/localtime:/etc/localtime:ro" \
                --network host \
                --name ${CONTAINER_NAME} \
                -u root \
                ${IMAGE_NAME}
            else
                # get display environment variable
                DISPLAY=$(printenv DISPLAY)
                
                # if host has gpu support
                docker run -it --rm --gpus all ubuntu:20.04 nvidia-smi &>/dev/null
                if [ $? == 0 ]; then
                    echo "Creating ${CONTAINER_NAME} with ${IMAGE_NAME} image and gpu support"
                    docker run -itd -u $(id -u):$(id -g) \
                    --gpus all \
                    --privileged \
                    --env="NVIDIA_DRIVER_CAPABILITIES=all" \
                    --env="QT_X11_NO_MITSHM=1" \
                    --env="DISPLAY=${DISPLAY}" \
                    --volume="/dev:/dev:rw" \
                    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
                    --volume="$(pwd)/packages/${CONTAINER_NAME}:/home/docker/ws/src:rw" \
                    --volume="${HOME}/.Xauthority:/root/.Xauthority:rw" \
                    --volume="/etc/localtime:/etc/localtime:ro" \
                    --hostname ${CONTAINER_NAME} \
                    --add-host ${CONTAINER_NAME}:127.0.1.1 \
                    -p 8080:8080/tcp -p 8080:8080/udp \
                    --name ${CONTAINER_NAME} \
                    -u docker \
                    ${IMAGE_NAME}
                else
                    echo "Creating ${CONTAINER_NAME} with ${IMAGE_NAME} image and no gpu support"
                    docker run -itd -u $(id -u):$(id -g) \
                    --privileged \
                    --env="QT_X11_NO_MITSHM=1" \
                    --env="DISPLAY=${DISPLAY}" \
                    --volume="/dev:/dev:rw" \
                    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
                    --volume="$(pwd)/packages/${CONTAINER_NAME}:/home/docker/ws/src:rw" \
                    --volume="${HOME}/.Xauthority:/root/.Xauthority:rw" \
                    --volume="/etc/localtime:/etc/localtime:ro" \
                    --hostname ${CONTAINER_NAME} \
                    --add-host ${CONTAINER_NAME}:127.0.1.1 \
                    -p 8080:8080/tcp -p 8080:8080/udp \
                    --name ${CONTAINER_NAME} \
                    -u docker \
                    ${IMAGE_NAME}
                fi
            fi
            docker exec -it ${CONTAINER_NAME} bash
        fi
        break
    elif [ ${COMMAND} == "run" ]; then
        if [[ -z $(docker container list -f "status=exited" | sed -n '2,$p') ]]; then
            echo -e "${COLOR_RED}Error: ${HIGHLIGHT}All containers are running or no container has been built, please create one first${COLOR_REST}"
        else
            # reading name with bash arguement support
            if [[ -z $2 ]]; then
                echo "The following are the containers you can run:"
                docker container list -f "status=exited" | sed -n '2,$p' | awk '{print $NF}'
                read -p "What container do you want to run? " CONTAINER_NAME
            else
                CONTAINER_NAME=$2
            fi
            while true; do
                if [[ -z $(docker container list -f "status=exited" | sed -n '2,$p' | awk '{print $NF}' | grep -w ${CONTAINER_NAME}) ]]; then
                    echo -e "${COLOR_RED}Error: ${HIGHLIGHT}The container does not exist or is running, please create it first${COLOR_REST}"
                elif [[ -n $(docker container list | sed -n '2,$p' | awk '{print $NF}' | grep -w ${CONTAINER_NAME}) ]]; then
                    echo -e "${COLOR_RED}Error: ${HIGHLIGHT}The container is already running${COLOR_REST}"
                else
                    echo "Starting ${CONTAINER_NAME}"
                    docker start ${CONTAINER_NAME}
                    break
                fi
                read -p "Please enter a stopped container name or empty to abort: " CONTAINER_NAME
                if [[ -z ${CONTAINER_NAME} ]]; then
                echo "Abort"
                    exit 0
                fi
            done
        fi
        break
    elif [ ${COMMAND} == "shell" ]; then
        if [[ -z $(docker container list -a | sed -n '2,$p') ]]; then
            echo -e "${COLOR_RED}Error: ${HIGHLIGHT}No containers has been built, please create one first${COLOR_REST}"
        else
            # reading name with bash arguement support
            if [[ -z $2 ]]; then
                echo "The following are the containers you can attach into shell:"
                docker container list -a | sed -n '2,$p' | awk '{print $NF}'
                read -p "What container do you want to attach into shell? " CONTAINER_NAME
            else
                CONTAINER_NAME=$2
            fi
            while true; do
                if [[ -z $(docker container list -a | sed -n '2,$p' | awk '{print $NF}' | grep -w ${CONTAINER_NAME}) ]]; then
                    echo -e "${COLOR_RED}Error: ${HIGHLIGHT}The container does not exist, please create it first${COLOR_REST}"
                elif [[ -n $(docker container list | sed -n '2,$p' | awk '{print $NF}' | grep -w ${CONTAINER_NAME}) ]]; then
                    docker exec -it ${CONTAINER_NAME} bash
                    break
                else
                    echo "The contatiner is not running, starting ${CONTAINER_NAME}"
                    docker start ${CONTAINER_NAME}
                    docker exec -it ${CONTAINER_NAME} bash
                    break
                fi
                read -p "Please enter an existing container name or empty to abort: " CONTAINER_NAME
                if [[ -z ${CONTAINER_NAME} ]]; then
                    echo "Abort"
                    exit 0
                fi
            done
        fi
        break
    elif [ ${COMMAND} == "stop" ]; then
        if [[ -z $(docker container list | sed -n '2,$p') ]]; then
            echo -e "${COLOR_RED}Error: ${HIGHLIGHT}There is currently no container running${COLOR_REST}"
        else
            # reading name with bash arguement support
            if [[ -z $2 ]]; then
                echo "The following is the containers that is currently running:"
                docker container list | awk '{print $NF}'
                read -p "Which one do you want to stop? " CONTAINER_NAME
            else
                CONTAINER_NAME=$2
            fi
            while [[ -z $(docker container list | sed -n '2,$p' | awk '{print $NF}' | grep -w ${CONTAINER_NAME}) ]]; do
                echo -e "${COLOR_RED}Error: ${HIGHLIGHT}The container does not exist or is not running${COLOR_REST}"
                read -p "Please choose a running container to stop or empty to abort: " CONTAINER_NAME
                if [[ -z ${CONTAINER_NAME} ]]; then
                    echo "Abort"
                    exit 0
                fi
            done
            docker stop ${CONTAINER_NAME}
        fi
        break
    else
        echo -e "${COLOR_RED}Error: ${HIGHLIGHT}Unknown option${COLOR_REST}"
        read -p "Please enter correct command or empty to abort. (create/run/shell/stop/empty): " COMMAND
        if [[ -z ${COMMAND} ]]; then
            echo "Abort"
            exit 0
        fi
    fi
done
