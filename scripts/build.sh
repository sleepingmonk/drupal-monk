#!/bin/bash

set -e

clean=false
confirmed=false
composer_install=true
db_drop=false
db_file=false
production_build=""

# Basic yes/no prompt handler.
# TODO: separate this into a helper.sh so it can be included in other scripts.
prompt_yes_no() {
  while true ; do
    printf "$* [yes/No] "
    read answer
    if [ -z "$answer" ] ; then
      return 1
    fi
    case $answer in
      [Yy][Ee][Ss])
        return 0
        ;;
      [Nn][Oo])
        return 1
        ;;
      *)
        echo "Please answer yes or no"
        ;;
    esac
  done
}

while getopts ":ci:ln:p:twy" opt; do
  case $opt in
    c )
      echo
      echo "-c Clean build."
      clean=true
      ;;
    i )
      echo
      echo "-i Import db file, $OPTARG"
      db_file=$OPTARG
      ;;
    l )
      echo
      echo "-l (live) Build production code."
      production_build="--no-dev"
      ;;
    y )
      confirmed=true
      ;;
    \?)
      echo
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo
      echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

# Check for existing build and confirm rebuild.
if $clean ; then
  if ! $confirmed ; then
    echo
    if prompt_yes_no "Do you want to destroy the current composer install and rebuild from composer.json?" ; then
      clean=true
    else
      echo
      echo "Installing without destroying first."
      clean=false
    fi
  fi
fi

if $clean ; then
  # Destroy Stuff.
  echo
  echo "Destroying Stuff..."

  echo
  echo "Removing dependencies, core and contrib for rebuild..."
  rm -rf drush/contrib/ \
    vendor/ \
    web/core/ \
    web/modules/contrib/ \
    web/themes/contrib/ \
    web/profiles/contrib/ \
    web/libraries/
fi

# Run composer install.
if ! $confirmed ; then
  echo
  if prompt_yes_no "Ready to run composer install?" ; then
    echo ok
    composer_install=true
  else
    echo
    echo "Exiting."
    exit 0
  fi
fi

if $composer_install ; then
  echo
  echo "Running composer install."
  composer install $production_build

  # echo
  # echo "Removing vendor subproject .git directories..."
  # # If committing vendor dir we don't manage these as git subprojects.
  # find ./vendor/ -type d -name ".git" | xargs rm -rf
  # # If committing web dir we don't manage these as git subprojects.
  # find ./web/ -type d -name ".git" | xargs rm -rf

fi

# Install a database file?
if [[ $db_file != false ]] ; then
  if [[ -f $db_file ]] ; then
    echo
    echo "Installing $db_file"
    echo
    cd /app/web
    if [ ${file: -4} == ".sql" ] ; then
      cat $db_file | drush sqlc
    fi
    if [ ${file: -3} == ".gz" ] ; then
      gunzip -c $db_file | drush sqlc
    fi
  else
    echo
    echo -e "\033[31m$db_file not found. Use path relative to current working directory.\033[0m"
    exit
  fi
fi

echo
echo "Done Build"
