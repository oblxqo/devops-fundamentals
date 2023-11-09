#!/bin/bash

# Navigate to the Angular application directory from ROOT_DIR/scripts folder
SCRIPT_DIR=`dirname "$(readlink -f "$BASH_SOURCE")"`
ROOT_DIR=${SCRIPT_DIR%/*}

cd $ROOT_DIR

# Set a flag to track whether errors occur
hasErrors=false

# Create a variable to store all errors
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

# Run the audit command and store any errors
echo "Running npm audit..."
auditErrors=$(npm audit 2>&1)
if [ $? -ne 0 ]; then
  hasErrors=true
  errorMessages+="Audit Errors:\n$auditErrors\n\n"
fi

# Check for errors and print them if necessary
if [ "$hasErrors" = true ]; then
  echo -e "Quality Check Failed: \n\n$errorMessages"
  exit 1
else
  echo "Quality Check Passed: No errors found!"
fi
