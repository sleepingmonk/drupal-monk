#!/usr/bin/env bash

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
# git tag -a $pantheon_prefix$pantheon_new -m "Tagging new pantheon live release."
