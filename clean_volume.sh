#!/usr/bin/env bash

# Deletes docker volumes matching a pattern.
# 1. Generate file
# docker system df -v > input.txt
# 2. Run the command
# ./clean_volume.sh 246.6MB

IFS='
'

if [ $# -eq 0 ]; then
 echo "no arguments"
 exit 1
fi

size=$1
for line in $(cat input.txt | grep $size); do
  id=$(echo $line | awk '{ print $1 }')
  link=$(echo $line | awk '{ print $2 }')
  if [ $link = "0" ]; then
    echo $line
    echo $link
    docker volume inspect "$id" | jq '.[0].CreatedAt'
    echo "Delete?"

    if [ $delete = "y" ]; then
      docker volume remove $id
    fi
  fi
done
