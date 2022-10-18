#!/usr/bin/env bash

# This file enables local deploy process without CI platform.
# This script can be run with a lando tooling command, or however you
# wish from your local environment.

set -e

BASEDIR=$(dirname $(dirname $(realpath $0)))
# Include colors.
. ${BASEDIR}/scripts/colors.sh
# This is named CIRCLE_BRANCH only to emulate a CIRCLE_CI deploy.
# Change to anything you want to set your $CI_BRANCH in .ci/scripts/deploy.sh
CIRCLE_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo
echo -e "${YELLOW}[] Is your branch (${CIRCLE_BRANCH}) up to date?"
echo -e "[] Have you made backups?"
echo -e "[] Is config synced?${RESET}\n"

read -p "Are you sure you want to deploy the current '${CIRCLE_BRANCH}' branch to '$target' environment? (y/N) " -n 1 -r

if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
  echo -e "\nNevermind."
  exit 0
fi
# New line after prompt.
echo -e "\n"
# Build
composer install --no-dev -o --working-dir=${BASEDIR} --dry-run
${BASEDIR}/scripts/theme.sh -a
# Test.
composer run lint --working-dir=${BASEDIR}
composer run code-sniff --working-dir=${BASEDIR}
composer run unit-test --working-dir=${BASEDIR}
# Deploy Artifact.
. ${BASEDIR}/.ci/scripts/deploy.sh
# Clean Up.
# Comment this line out to speed up future local deploys.
rm -rf ${BASEDIR}/data/artifact

exit 0
