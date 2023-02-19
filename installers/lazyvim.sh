#!/bin/bash -ex

git clone --recursive https://github.com/LazyVim/starter.git nvim_temp
rm -rf nvim_temp/.git
cp -rf nvim_temp/* nvim
rm -rf nvim_temp
