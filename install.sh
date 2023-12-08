#!/bin/bash
set -e
set -x

NTURT_DOCKER_DIR=$(dirname $(realpath $0))
INSTALL_DIR=/usr/local/bin

# install python modules
pip3 install argcomplete docker prettytable PyYAML

# enable argcomplete globally
# referenced from: https://github.com/kislyuk/argcomplete/blob/develop/scripts/activate-global-python-argcomplete
# bash
if [[ ! -f ~/.bash_completion ]]; then
    touch ~/.bash_completion
fi
if ! grep -q "argcomplete" ~/.bash_completion; then
    echo "source .local/lib/python3.10/site-packages/argcomplete/bash_completion.d/_python-argcomplete" >> ~/.bash_completion
fi
# zsh
if [[ ! -f ~/.zshenv ]]; then
    touch ~/.zshenv
fi
if ! grep -q "argcomplete" ~/.zshenv; then
    echo 'fpath=( .local/lib/python3.10/site-packages/argcomplete/bash_completion.d "${fpath[@]}" )' >> ~/.zshenv
fi

# install nturt_docker
if [[ -s ${INSTALL_DIR}/nturt_docker ]]; then
    sudo rm ${INSTALL_DIR}/nturt_docker
fi
sudo ln -s ${NTURT_DOCKER_DIR}/nturt_docker.py ${INSTALL_DIR}/nturt_docker

echo "Installation complete"
