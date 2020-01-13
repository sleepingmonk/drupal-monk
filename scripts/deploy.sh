#!/bin/sh

set -e

project=[project]
deploy_env=$1
artifact=[artifact git url]

echo "\nUpdating artifact and branch: $deploy_env\n" 
if [ ! -d /app/data/artifact ] ; then
  echo "\nCloning artifact...\n"
  cd /app/data && git clone $artifact artifact
fi

cd /app/data/artifact

git checkout $deploy_env
git pull origin $deploy_env

echo "\nSyncing Artifact\n"
cd /app
git checkout $deploy_env
git pull origin $deploy_env
composer artifact-sync

echo "\nCommitting and pushing code.\n"
cd /app/data/artifact

# @todo: add any taging requirements for production deploy.
# if $deploy_env == master ...

git add .
git commit -m "Manual Deploy with lando"
git push origin
