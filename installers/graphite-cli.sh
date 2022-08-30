#!/bin/bash -ex

# https://github.com/withgraphite/graphite-cli

# Make nvm available in this shell script
export NVM_DIR=$HOME/.nvm
source $NVM_DIR/nvm.sh

# Clone, build and install the gt CLI
REPO_PATH="$HOME/code/repos/graphite-cli"

cd ~/code/repos
if [ ! -d "$REPO_PATH" ]; then
    git clone https://github.com/withgraphite/graphite-cli.git "$REPO_PATH"
fi
cd graphite-cli
git pull
cat .nvmrc | nvm install
nvm use
npm install --global yarn
yarn install
yarn build

# gt CLI is now available in $HOME/code/repos/graphite-cli/dist/src/index.js

# Run tests
# DEBUG=1 yarn test --full-trace
