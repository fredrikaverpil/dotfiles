#!/bin/bash -ex

# https://github.com/einride/gh-dependabot
# NOTE: gh dependabot --org einride --team einride/transportation-platform
gh extension install einride/gh-dependabot

# https://github.com/dlvhdr/gh-dash
gh extension install dlvhdr/gh-dash

# https://docs.github.com/en/copilot/github-copilot-in-the-cli
gh extension install github/gh-copilot

# https://github.com/meiji163/gh-notify
gh ext install meiji163/gh-notify

gh ext upgrade --all
