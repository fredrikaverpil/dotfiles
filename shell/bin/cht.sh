#!/bin/bash

languages=$(echo "python typescript rust golang c" | tr " " "\n")
core_utls=$(echo "find xargs sed awk" | tr " " "\n")
selected=$(echo -e "$languages\n$core_utls" | fzf)

read -p "Enter the search term: " query

if echo "$languages" | grep -q "$selected"; then
	curl cht.sh/$selected/$(echo $query | tr " " "+")
else
	curl cht.sh/$selected-$query
fi
