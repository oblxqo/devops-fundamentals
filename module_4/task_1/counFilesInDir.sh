#!/bin/bash

# Check if any arguments are provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 directory [directory ...]"
  exit 1
fi

# Loop through each argument
for DIR in "$@"; do
  if [ ! -d "$DIR" ]; then	# Check if argument is a valid directory
    echo "Error: $DIR is not a valid directory"
    continue
  fi

  # Count the number of files in the directory and its subdirectories
  FILECOUNT=$(find "$DIR" -type f | wc -l)

  echo "$DIR: $FILECOUNT"
done