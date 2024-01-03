#!/bin/bash

# Navigate to the root directory
SCRIPT_DIR=`dirname "$(readlink -f "$BASH_SOURCE")"`
ROOT_DIR=${SCRIPT_DIR%/*}

cd $ROOT_DIR

# Set a flag to track if errors occur
hasErrors=false

# Create a string to contain all error messages
errorMessages=""

echo "Run Quality Check..."

# Run the lint command and store any errors
echo "Checking code quality with linting..."
lintErrors=$(ng lint 2>&1)
if [ $? -ne 0 ]; then
  hasErrors=true
  errorMessages+="Lint Errors:\n$lintErrors\n\n"
fi

# Run the test command and store any errors
echo "Running unit tests..."
testErrors=$(ng test --watch=false --code-coverage 2>&1)
if [ $? -ne 0 ]; then
  hasErrors=true
  errorMessages+="Test Errors:\n$testErrors\n\n"
fi

# Run the npm audit command for dependencies check and store any errors
echo "Running npm audit..."
auditOutput=$(npm audit --parseable | tee /dev/stderr)
auditErrors=$(echo "$auditOutput" | grep 'https://github.com/advisories/' | awk -F $'\t' '{print $1,$4}')

if [ ! -z "$auditErrors" ]; then
  hasErrors=true
  errorMessages+="Dependencies Audit:\n${auditErrors}\n\n"
fi


# Run the sonar scanner for static code analysis and store any errors
echo "Running sonar scanner..."
sonarOutput=$(npm run sonar 2>&1 | tee /dev/stderr)
sonarErrors=$(echo "$sonarOutput" | awk '/ERROR/{flag=1}/INFO/{flag=0}flag')
if [ ! -z "$sonarErrors" ]; then
  hasErrors=true
  errorMessages+="Sonar Errors:\n$sonarErrors\n\n"
fi

# Print any errors if they were found
if [ "$hasErrors" = true ]; then
  echo -e "Quality Check Failed with following Errors:\n$errorMessages"
  exit 1
else
  echo "Quality Check Passed: No errors found!"
fi
