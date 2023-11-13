#!/bin/bash -ex

# clone down all my public repos from github

cd ~/code
GH_USER=fredrikaverpil
PAGE=1
curl "https://api.github.com/users/$GH_USER/repos?page=$PAGE&per_page=100" | grep -e 'clone_url*' | cut -d \" -f 4 | xargs -L1 git clone --recursive
