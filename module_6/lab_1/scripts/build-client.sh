#!/bin/bash

# Navigate to the Angular application directory from ROOT_DIR/scripts folder
SCRIPT_DIR=`dirname "$(readlink -f "$BASH_SOURCE")"`
ROOT_DIR=${SCRIPT_DIR%/*}
clientBuildFile=$ROOT_DIR/dist/client-app.tar.gz

# Load environment variables
export $(grep -v '^#' $ROOT_DIR/.env | xargs -d '\n')

# Check if the client-app.zip exists
if [ -e "$clientBuildFile" ]; then
  echo "$clientBuildFile already exists, removing the file..."
  rm $clientBuildFile
  echo "$clientBuildFile was removed."
fi

# Install the app's npm dependencies
echo "Installing npm dependencies..."
cd $ROOT_DIR
npm ci

# Invoke the client app's build command with --configuration flag
echo "Building client app with configuration: $ENV_CONFIGURATION..."
npm run build --configuration="$ENV_CONFIGURATION"

# Compress all built content/files in one client-app.tar.gz file
echo "Compressing built files into client-app.tar.gz..."
tar --gzip --xattrs -cpf $clientBuildFile $ROOT_DIR/dist/

# Count the number of files in the client app's dist folder
echo "Counting the number of files in the dist folder..."
file_count=$(find $ROOT_DIR/dist/ -type f | wc -l)
echo "There are $file_count files in the dist folder."

echo "Build finished!"
