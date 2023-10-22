#!/bin/bash

# Check if a threshold is provided and is a valid integer between 0 and 100
if [ $# -eq 0 ]; then
  THRESHOLD=10
elif [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 0 ] && [ "$1" -le 100 ]; then
  THRESHOLD=$1
else
  echo "Invalid threshold value: $1. Please provide an integer between 0 and 100."
  exit 1
fi

# Get the free space information for all non-virtual filesystems and check if they're below the threshold
DISKS=$(df -h | grep -vE '(tmpfs|devtmpfs|proc|sysfs)' | tail -n +2 | awk '{print $1}')
for DISK in $DISKS; do
  PERCENT_FREE=$(df -h "$DISK" | awk '{print $5}' | tail -n 1 | cut -d'%' -f1)
  if [ "$PERCENT_FREE" -lt "$THRESHOLD" ]; then
    echo "WARNING: Free space on $DISK is below $THRESHOLD%"
  fi
done
