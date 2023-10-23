#!/bin/bash

typeset fileName=users.db
typeset fileDir=../data
typeset filePath=$fileDir/$fileName

create_users_db() {
  read -r -p "users.db does not exist. Do you want to create it? [Y/n] " answer
  answer=${answer,,}
  if [[ "$answer" =~ ^(yes|y)$ ]]; then
    mkdir -p $fileDir && touch $filePath
    echo "File ${fileName} was created."
  else
    echo "File ${fileName} must be created to continue. Try again." >&2
    exit 1
  fi
}

valid_latin_letters() {
  [[ $1 =~ ^[a-zA-Z_]+$ ]]
}

add_user() {
  [ ! -f $filePath ] && create_users_db

  read -p "Enter a username: " username

  if ! valid_latin_letters "$username"; then
    echo "Invalid username. Please use Latin letters only."
    exit 1
  fi

  read -p "Enter a role: " role

  if ! valid_latin_letters "$role"; then
    echo "Invalid role. Please use Latin letters only."
    exit 1
  fi

  echo "${username}, ${role}" | tee -a $filePath
}

backup() {
  [ ! -f $filePath ] && create_users_db

  backupFileName="$(date +'%Y-%m-%d-%H-%M-%S')-$fileName.backup"
  cp $filePath $fileDir/$backupFileName

  echo "Backup is created."
}

restore() {
  backup_file=$(ls $fileDir/*-$fileName.backup | tail -n1)

  if [[ ! -f "$backup_file" ]]; then
    echo "No backup file found."
    exit 1
  else
    cp "$backup_file" $filePath
    echo "Restored from backup."
  fi
}

find_user() {
  [ ! -f $filePath ] && create_users_db

  read -p "Enter a username: " username

  output=$(awk -F, -v x=$username '$1 ~ x' $filePath)

  if [ -z "$output" ]; then
    echo "User not found."
  else
    echo "Found users:"
    echo "$output"
  fi
}

list_users() {
  [ ! -f $filePath ] && create_users_db

  if [ "$1" == "--inverse" ]; then
    cat --number $filePath | tac
  else
    cat --number $filePath
  fi
}

print_help() {
  echo "Manages users in db. It accepts a single parameter with a command name."
  echo
  echo "Syntax: db.sh [command]"
  echo
  echo "List of available commands:"
  echo
  echo "add       Adds a new line to the users.db. Script must prompt user to type a
                    username of new entity. After entering username, user must be prompted to
                    type a role;"
  echo "backup    Creates a new file, a copy of current database;"
  echo "find      Prompts user to type a username, then prints username and role if such
                    exists in users.db. If there is no user with selected username, script must print:
                    “User not found”. If there is more than one user with such username, print all
                    found entries;"
  echo "list      Prints contents of users.db in format: N. username, role
                    where N – a line number of an actual record
                    Accepts an additional optional parameter --inverse which allows to get
                    result in an opposite order – from bottom to top;"
}

case "$1" in
add)      add_user ;;
backup)   backup ;;
find)     find_user ;;
help)     print_help ;;
list)     list_users $2 ;;
restore)  restore ;;
*)        print_help ;;
esac
