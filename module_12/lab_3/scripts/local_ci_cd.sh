#!/bin/bash

# Declare Variables
SSH_ALIAS=dev-cent
SSH_USER_NAME=sshuser
SCRIPT_DIR=`dirname "$(readlink -f "$BASH_SOURCE")"`
ROOT_DIR=${SCRIPT_DIR%/*}
CLIENT_REMOTE_DIR=/var/www/angular-cent-shop.net
clientBuildFile=$ROOT_DIR/dist/client-app.tar.gz

# Function to Check Remote Directory
check_remote_dir_exists() {
  echo "Check if remote directories exist"

  if ssh $SSH_ALIAS "[ ! -d $1 ]"; then
    echo "Creating: $1"
	ssh -t $SSH_ALIAS "sudo bash -c 'mkdir -p $1 && chown -R $SSH_USER_NAME: $1'"
  else
    echo "Clearing: $1"
    ssh $SSH_ALIAS "rm -r $1/*"
  fi
}

# Quality Check
echo "Running Quality Check..."
bash $SCRIPT_DIR/quality-check.sh

# Building App
echo "Building App..."
bash $SCRIPT_DIR/build-client.sh

# Check If Remote Directory Exists and Clear the Remote Directory
check_remote_dir_exists $CLIENT_REMOTE_DIR

# Copy and Extract Files to Remote Server
echo "Copying and extracting files to the remote server"
scp $ROOT_DIR/dist/client-app.tar.gz $SSH_ALIAS:$CLIENT_REMOTE_DIR
ssh $SSH_ALIAS "tar -xvf $clientBuildFile -C $CLIENT_REMOTE_DIR && rm $clientBuildFile"

echo "App is successfully deployed on the server"
