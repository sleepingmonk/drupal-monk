#!/bin/bash

set -e

# Disable strict host checking so we can push code and run drush on all envs.
echo -e "Host [artifact repo host]\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
echo -e "Host [develop host] no\n" >> ~/.ssh/config
echo -e "Host [stage host]\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
echo -e "Host [live host]\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config

TIMESTAMP=$(date +'%y-%m-%dT%H:%m:%S')
HOST_ENV=$CIRCLE_BRANCH

git config --global user.email "$GIT_EMAIL"
git config --global user.name "Ch3-P0"

echo "\nClone artifact.\n"
mkdir -p data
cd data
git clone $ARTIFACT_GIT artifact
echo "\nCheckout $CIRCLE_BRANCH\n"
cd artifact
git fetch origin && git checkout $CIRCLE_BRANCH
git pull origin $CIRCLE_BRANCH
echo "\nSync to artifact.\n"
cd ../.. && composer -n artifact-sync
cd data/artifact
git add .
git commit -am "Built assets. $TIMESTAMP"
echo "\n@todo- Work out release taging.\n"

# This conditional is tags master banch for live deployment on Pantheon.
# Remove pantheon specific code if it's not needed.
# I also sets the environment name for the master branch if it doesn't match
# the branch name. Used for drush aliases later in the script. Adapt as needed.
if [ $CIRCLE_BRANCH == 'master' ] ; then
  # For drush reset.
  HOST_ENV=live

  # Get latest pantheon_live_ tag.
  git fetch origin --tags
  pantheon_prefix='pantheon_live_'
  pantheon_current=$(git tag -l --sort=v:refname $pantheon_prefix* | tail -1)
  if [ -z $pantheon_current ] ; then
    # No current tag so start with 1.
    pantheon_new=1
  else
    pantheon_id=${pantheon_current#${pantheon_prefix}}
    pantheon_new=$(($pantheon_id+1))
  fi
  echo
  echo "Tagging master branch for production (Live): $pantheon_prefix$pantheon_new"

  echo -e "\nNOT REALLY - no tagging pre-production. Delete this message and uncomment git tag command below to go live."
  git tag -a $pantheon_prefix$pantheon_new -m "Tagging new pantheon live release."
fi

echo
echo "Pushing $CIRCLE_BRANCH"
git push origin $CIRCLE_BRANCH -f --tags

# Reset env.

# Give pantheon a chance for code to sync first.
# May need to adjust this value.

WAIT=40
echo
echo "Waiting $WAIT seconds for code to sync on host."
sleep $WAIT

echo
echo Clearing Cache for $HOST_ENV
drush @p.$HOST_ENV cr

echo
echo Running Database Updates for $HOST_ENV
drush @p.$HOST_ENV updb -y

echo
echo Importing Config for $HOST_ENV
drush @p.$HOST_ENV cim

echo
echo Clearing Cache for $HOST_ENV
drush @p.$HOST_ENV cr
