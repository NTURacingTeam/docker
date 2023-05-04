#!/bin/bash

# declare text styles
COLOR_REST='\e[0m'
HIGHLIGHT='\e[0;1m'
REVERSE='\e[0;7m'
COLOR_GREEN='\e[0;32m'
COLOR_RED='\e[1;31m'

# add display host
if [ $(uname) == "Linux" ]; then
    xhost local:root &>/dev/null
    xhost +local:root &>/dev/null
fi

# build docker image
# reading image file name with bash arguement support
if [[ -z $(ls Dockerfile) ]]; then
    echo -e "${COLOR_RED}Error: ${HIGHLIGHT}No image availible in directory 'Dockerfile'${COLOR_REST}"
elif [[ -z $1 ]]; then
    echo "The following are the docker images in directory 'Dockerfile' that you can build your image from:"
    ls -l Dockerfile | sed -n '2,$p' | awk '{print $NF}'
    read -p "Which image do you want to build? " IMAGE_FILE
else
    IMAGE_FILE=$1
fi
while [[ -z $(ls Dockerfile | grep -w ${IMAGE_FILE}) ]]; do
    echo -e "${COLOR_RED}Error: ${HIGHLIGHT}Unknown image file${COLOR_REST}"
    read -p "Please enter correct image file you want to build form or empty to abort. " IMAGE_FILE
    if [[ -z ${IMAGE_FILE} ]]; then
    echo "Abort"
        exit 0
    fi
done

# using no-cache to prevent problems arise from apt-get update
if [[ -z $(docker images | sed -n '2,$p' | grep -w ${IMAGE_FILE} | awk '{print $2}' | grep -w latest) ]]; then
    echo "Building '${IMAGE_FILE}:latest' from ${IMAGE_FILE}"
    docker build -t ${IMAGE_FILE}:latest -f ./Dockerfile/${IMAGE_FILE} . --no-cache
else
    read -p "The image '${IMAGE_FILE}:latest' already exist, do you want to repalce it? (y/n):" TO_BUILD
    while true; do
        if [[ ${TO_BUILD} == "y" || ${TO_BUILD} == "yes" ]]; then
            I=1
            while [[ -n $(docker images | sed -n '2,$p' | grep -w ${IMAGE_FILE} | grep -w older_version${I}) ]]; do
                I=$(( ${I} + 1 ))
            done
            echo "Rename '${IMAGE_FILE}:latest' to '${IMAGE_FILE}:older_version${I}', and building '${IMAGE_FILE}:latest' from ${IMAGE_FILE}"
            docker tag ${IMAGE_FILE}:latest ${IMAGE_FILE}:older_version${I}
            docker build -t ${IMAGE_FILE}:latest -f ./Dockerfile/${IMAGE_FILE} . --no-cache
            break
        elif [[ ${TO_BUILD} == "n" || ${TO_BUILD} == "no" ]]; then
        echo "Abort with no action"
            break
        else
            echo -e "${COLOR_RED}Error: ${HIGHLIGHT}Unknown option${COLOR_REST}"
            read -p "Please enter correct option or empty to abort. (y/n/empty): " TO_BUILD
            if [[ -z ${TO_BUILD} ]]; then
            echo "Abort"
                exit 0
            fi
        fi
    done
fi
