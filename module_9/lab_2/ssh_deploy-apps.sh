#!/bin/bash

SERVER_HOST_DIR=$(pwd)/nestjs-rest-api
CLIENT_HOST_DIR=$(pwd)/shop-react-redux-cloudfront

# destination folder names can be changed
SERVER_REMOTE_DIR=/var/app/cent-shop.net
CLIENT_REMOTE_DIR=/var/www/cent-shop.net

NGINX_CONF_LOCAL_FILE=$(pwd)/devops-js-app.conf
NGINX_CONF_REMOTE_DIR=/etc/nginx/conf.d

LOCAL_CERT_PATH=$(pwd)/ssl

REMOTE_CERT_FOLDER=/etc/ssl/certs
REMOTE_KEY_FOLDER=/etc/ssl/private

SSH_ALIAS=dev-cent
SSH_USER_NAME=sshuser

check_remote_dir_exists() {
  echo "Check if remote directories exist"

  if ssh $SSH_ALIAS "[ ! -d $1 ]"; then
    echo "Creating: $1"
	ssh -t $SSH_ALIAS "sudo bash -c 'mkdir -p $1 && chown -R $SSH_USER_NAME: $1'"
  else
    echo "Clearing: $1"
    ssh $SSH_ALIAS "sudo -S rm -r $1/*"
  fi
}

check_remote_dir_exists $SERVER_REMOTE_DIR
check_remote_dir_exists $CLIENT_REMOTE_DIR

echo "---> Building and copying server files - START <---"
echo $SERVER_HOST_DIR
cd $SERVER_HOST_DIR && npm run build
scp -Cr dist/ package.json $SSH_ALIAS:$SERVER_REMOTE_DIR
echo "---> Building and transfering server - COMPLETE <---"

echo "---> Building and transfering client files, cert and ngingx config - START <---"
echo $CLIENT_HOST_DIR
cd $CLIENT_HOST_DIR && npm run build && cd ../
scp -Cr $CLIENT_HOST_DIR/dist/* $SSH_ALIAS:$CLIENT_REMOTE_DIR

# Copy NGINX config to remote machine
scp $NGINX_CONF_LOCAL_FILE $SSH_ALIAS:$NGINX_CONF_REMOTE_DIR

# Copy SSL certificate and SSL certificate key to remote machine
scp "${LOCAL_CERT_PATH}/cent-shop.crt" $SSH_ALIAS:$REMOTE_CERT_FOLDER/cent-shop.crt
scp "${LOCAL_CERT_PATH}/cent-shop.key" $SSH_ALIAS:$REMOTE_KEY_FOLDER/cent-shop.key

echo "---> Building and transfering - COMPLETE <---"