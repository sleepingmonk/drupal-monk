#!/usr/bin/env bash

set -e

BASEDIR=$(dirname $(dirname $(realpath $0)))
# Include Colors
. ${BASEDIR}/scripts/colors.sh
# These vars can be set in the CI config as env vars to keep out of this repo.
# Comment/remove or set them here if you're not worried about it.
GIT_EMAIL=
GIT_USER=
TIMESTAMP=$(date +'%y-%m-%dT%H:%m:%S')
# The repo this build syncs to is the artifact.
ARTIFACT_HOST=
ARTIFACT_PATH=
ARTIFACT_GIT=${ARTIFACT_HOST}/${ARTIFACT_PATH}
# Hostnames for our environments.
DEV_HOST=
STAGE_HOST=
PROD_HOST=
# See project README.md for workflow.
PROD_BRANCH=master
# The branch that triggered CI.  i.e. $CIRCLE_BRANCH or some other method of
# detection for your CI tooling.
CI_BRANCH=
# Produciton branch may not be named "production".
if [ $CI_BRANCH == $PROD_BRANCH ] ; then
  HOST_ENV=production
else
  HOST_ENV=$CI_BRANCH
fi
# If true, production deploy should fail if working repo was not tagged.
# If false, increment patch version of latest tag.
# If ignore, don't tag if no previous version found.
TAG_FAIL=true

# Disable strict host checking so we can push code and run drush on all envs.
echo -e "Host ${ARTIFACT_HOST}\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
echo -e "Host ${DEV_HOST}\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
echo -e "Host ${STAGE_HOST}\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
echo -e "Host ${PROD_HOST}\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config

# Make sure git user is set.
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"

echo "\nClone artifact.\n"
git clone $ARTIFACT_GIT data/artifact

echo "\nCheckout $CI_BRANCH\n"
cd ${BASEDIR}/data/artifact
git fetch origin
git checkout $CI_BRANCH
git pull origin $CI_BRANCH

echo "\nSync to artifact.\n"
composer -n artifact-sync --working-dir=${BASEDIR}
git add .
git commit -am "Built assets. $TIMESTAMP"

# This conditional tags master banch for production deployment.
# Uncomment pantheon live line if you're hosting on Panthon.
if [ $HOST_ENV != $CI_BRANCH ] ; then
  # . ${BASEDIR}/.ci/scripts/pantheon_live.sh
  . ${BASEDIR}/.ci/scripts/semver_production.sh
fi
echo -e "\nPushing $CI_BRANCH"
git push origin $CI_BRANCH -f --tags

# Run updates. See /drush/sites for aliases.
# Give production a chance for code to sync first.
# May need to adjust this value.
WAIT=40
echo
echo "Waiting $WAIT seconds for code to sync on host."
sleep $WAIT

echo
echo Running Database Updates for $HOST_ENV
drush @p.$HOST_ENV updb -y

echo
echo Importing Config for $HOST_ENV
drush @p.$HOST_ENV cim -y

echo
echo Clearing Cache for $HOST_ENV
drush @p.$HOST_ENV cr
