# Readme

## Meta

This document should be updated by *YOU*, as necessary as the project evolves.
Add your author information for historical reference and professional context, as:
 - `Date first edited: NAME (email)`


### Authors:
 - 2020-01-10: Calvin (sleepingmonk)

### Project Info:
 [repo]: https://github.com/<user>/<project>
 [host]: <host url>
 [ci]: <platform url>
 [backend]: https://drupal.org/8
 [frontend]: <drupal theme|headless repo>

 - Working Repo: [Github][repo]
 - Hosting: [<hostname>][host]
 - CI/CD: [<platform>][ci] - <status widget if available>
 - Backend: [Drupal 8][backend]
 - Frontend: [<frontend name>][frontend]

### Contents

 - [Local Development](#user-content-local-development)
 - [Module Management](#user-content-module-management)
   - [Adding Contrib Modules](#user-content-adding-contrib-modules)
   - [Updating Core](#user-content-updating-core)
   - [Updating Contrib Modules](#user-content-updating-contrib-modules)
   - [Removing Contrib Modules](#user-content-removing-contrib-modules)
   - [Applying Patches](#user-content-applying-patches)
 - [Git Workflow and Deploying Code](#user-content-git-workflow-and-deploying-code)
   - [Parallel Workflow](#user-content-git-workflow-and-deploying-code)
   - [Testing and Approval](#user-content-testing-and-approval)
   - [Automated Testing](#user-content-automated-testing)
   - [Deploying Code](#user-content-deploying-code)
 - [Troubleshooting Local Environment](#user-content-troubleshooting-local-environment)

## Local Development

* Docker: https://www.docker.com/community-edition
* Lando: https://docs.devwithlando.io

Once installed cd to project directory and type `lando` for a list of commands.

*Spin up the local:*

 - `lando start` - Spin up the environment.
 - `lando db-import [path to db]` - Import your database. Store db in `data/`.
 - `lando composer install` - Composer install.
 - `lando tb` - Build the theme assets.
 - `lando reset` - Runs updb, cim, cr ...

**Ready to work.**


## Module Management

From the project root:

### Adding Contrib Modules

 - `lando composer require drupal/[package_name] --no-update` to add it to the composer.json without updating everything.
 - `lando composer update drupal/[package_name]` to fetch/update only the desired module.

### Updating Core

- `lando composer update drupal/core drupa/core-recommended --with-dependencies -o`

### Updating Contrib Modules

 - `lando composer update drupal/[package_name]`

Sometimes several contrib modules are several versions behind.

*Do not use `lando composer update` without specifying a module, or it will update everything that's outdated at once, possibly introducing regressions which you'll have to do much more testing for.*

*Updates should be controlled and tested well. It's easiest to do that in smaller chunks. Especially watch out for BETA, ALPHA, or DEV versions of modules which are not stable and make no guarantees about not breaking things between updates. Ideally, never use Alpha/Dev modules and use BETA's sparingly. Consider contributing to the project to help get it to a full release.*

### Removing Contrib Modules

Enabled modules should be removed from a code base in 2 separate releases. The first release update should simply uninstall the module. The second release should remove the module from the codebase as described below. If you do it all at once Drupal will not be able to find the module code to be able to uninstall it, because it won't exist anymore.

Phase 1: Uninstall the module:

 - `lando drush pmu [module]` - uninstall the module.
 - `lando drush cex` - export the config changes caused by uninstalling the module.
 - Deploy the changes to update the Production site.

Phase 2: Remove the module:

 - `lando composer remove [package] --no-update` will remove a package from require or require-dev, without running all updates.
 - `lando composer update [package]` will remove the package code.
 - A clean build `lando build -c` of the codebase will delete contribs and vendor code and rebuild, without the removed modules.

### Applying Patches

If you need to apply patches, you can do so with the
[composer-patches](https://github.com/cweagans/composer-patches) plugin.

To add a patch to drupal module foobar insert the patches section in the extra
section of composer.json:
```json
"extra": {
    "patches": {
        "drupal/foobar": {
            "Patch description": "URL to patch"
        }
    }
}
```

## Git Workflow and Deploying Code

This project is configured for a Parallel Git Workflow on Pantheon using multidev environments.

ENV -> GIT BRANCH

 - develop (multidev) -> `develop`
 - stage (multidev) -> `stage`
 - Live (default pantheon live) -> `master`

In this way `master` is ALWAYS clean production code.

New feature branches for any work should be branched from `master` so it starts clean.  If you branch from anything else, you will carry in code that's not related to your ticket that can be hard to separate for deployment to Production if your code is approved, but the other code is not. Your branch will be "contaminated". Stay clean to not accidentally introduce rejected code to production and to not frustrate whoever needs to deploy project code with precision.

Push your feature to the working repo and make a Pull Request to `develop`.  This will be merged and deployed to the develop environment for INTERNAL review/QA.

If that passes, merge the clean FEATURE branch into `stage` for deploy to the stage environment for CLIENT review/approval.

If it's approved for deployment to production, merge the clean FEATURE branch into `master` for deploy to the Production environment.

In this way, individual features can move through the environments without affecting, or being affected by, other work in progress. Issues can stall in any environment for any reason and not hold up the progress of any other issues in development.  Hotfixes and security updates can breeze through without having to worry about whether or not you can deploy the 5 other things that might already have been sitting on stage for the last 3 months.

### Testing and Approval

A **solo dev** with limited oversight could be trusted to approve at the develop level, so the develop environment step may not be necessary. Leave it in place for when you need more detailed internal review.  Just remember that stage and Live will get ahead of it if you don't use it on every deploy, so you'll need to merge master into develop first, if you want a clean and concise Pull Request into develop.

Features should always be approved by the client on stage. Avoid doing internal review on stage because if it fails, stage would be contaminated with a feature not ready for client review which can be confusing to the client or PM in some cases.

Though a solo dev may be trusted to deploy a feature or update without client approval, requiring client approval and signoff is recommended to help spot issues we may have blind spots for, and to protect us from breakage on production.

### Automated Testing

 - Would be nice.
 - Would make the above process more streamlined, automated, and less stressfull.

### Deploying Code

This should be handled automatically by [CI/CD][host].  However, the deploy scripts can be run manually from a local environment if needed.  There is a helper script that can be run via lando, but you must manually run the build steps first:

 - `lando composer install (--no-dev -o)` - build the composer project (drupal).
 - `lando tb` - build the theme assets.
 - `lando deploy [develop|stage|master]` - see below.

The deploy command will:

 - clone the production artifact (you will need keys and permissions for host).
 - checkout the appropriate envrionment branch
 - sync the appropriate files from this working repo to the artifact repo
 - commit the changes to the artifact
 - (if a deploy to master) tag the commit for deployment to the Live environment (Make sure you're sure and have a backup!).
 - push the artifact changes back up to [Repo][repo]

CI[ci] should do all this for you upon merge to the environment branches. Scripts should run post deploy drush commands like `updb -y`, `cim -y`, `cr`.  Make sure you check this for failure and run manually if needed.

This process keeps working code separate from production code.


## Troubleshooting Local Environment

With mysterious composer commands or theme building issues try any of the following, in order of least to most destructive:

 - `lando restart` to restart the services.
 - `lando rebuild` to rebuild local containers if restart didn't help.
 - Restart Docker: because `lando rebuild` didn't help and you just need to flush the system.
 - `lando destroy && lando start` because Docker Restart didn't help and you _*really*_ mean it this time. (Database will be lost and you will need to re-import.  Hopefully you didn't have anything important in there.)
 - NUKE VIRTUALIZATION TOOLS - Reinstall Lando, or Docker, or Both. *Obviously a last resort.* You shouldn't have to do this, unless maybe you updated one or the other recently and something isn't right. You will lose all existing docker images and containers if you re-install Docker.
 - Flip Table (╯°□°）╯︵ ┻━┻  - Re-evaluate your life.
