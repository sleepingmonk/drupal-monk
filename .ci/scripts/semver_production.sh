#!/usr/bin/env bash

SEMVER_REGEX='^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$'
version=

# Get latest production tag.
git fetch origin --tags
version=$(git describe --tags)
if [ -z $version ] ; then
  case $TAG_FAIL in
    false)
      echo -e "${YELLOW}No current tag so starting with 0.0.1${RESET}"
      version=0.0.1
      ;;

    ignore)
      echo -e "${GREEN}No current tag. Ignoring."
      ;;

    *)
      echo -e "${RED}Missing or invalid version tag on source repo: ${version}${RESET}"
      exit 1
      ;;
  esac
else
  # Check if valid semver.
  if [[ $version =~ $SEMVER_REGEX ]] ; then
    echo -e "${GREEN}Production tag found: ${version}${RESET}"
  else
    case $TAG_FAIL in
      true)
        echo -e "${RED}Missing or invalid version tag on source repo: ${version}${RESET}"
        exit 1
        ;;

      *)
        # Get the most resent semver tag.
        version=$(git tag -l  --sort=v:refname [0-9].[0-9].[0-9] | tail -1)
        if [ -z $version ] ; then
          echo -e "${YELLOW}No current tag so starting with 0.0.1${RESET}"
          version=0.0.1
        else
          echo -e "${YELLOW}No current tag so incrementing patch on most resent version: ${version}${RESET}"
          version_new=${version%.*}.$((${version##*.}+1))
          version=$version_new
        fi
        ;;
    esac
  fi
fi

echo -e "\nTagging master branch for production (Live): $version"

git tag -a $version -m "Tagging new produciton release."
