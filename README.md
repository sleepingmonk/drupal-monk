## Requirements

* Docker: https://www.docker.com/community-edition
* Lando: https://docs.devwithlando.io
* Monkey Wrench: https://bitbucket.org/cheekymonkeymedia/monkey-wrench


## Local Development

### Get latest code and start a feature branch.

- Clone the working repo (bitbucket).
- `cd [project root]`
- `git checkout master` - Start all new features from master.
- `git pull origin master` - To make sure you have the latest code.
- `git checkout -b feature/[ID-123]--[short-description]` - Create new feature branch thusly.

### Install site in local docker environment with Lando tooling.

*First time setup, please remember the following:*

- Make sure `web/sites/default/services.local.yml` is in place. (see `mw copy`)
- Make sure `web/sites/default/settings.local.php` is in place. (see `mw copy`)
- Make sure `web/sites/default/settings.php` includes settings.local.php.
  - Double check your db settings etc in the above files.
  - Use `lando info` for db connection info.
- Import your database. `lando db-import`

*Spin up the local:*

- `lando start` - Spin up the environment.
- `lando build -y` - Clean composer install.
- `lando build:theme` - Build the theme assets.
- `lando build:reset` - Runs local-dev.sh to updb, cim, cr ...

**Ready to work.**


## Module Management

From the project root:

### Adding Contrib Modules

- `lando composer require drupal/[package_name] --no-update` to add it to the composer.json without updating everything.
- `lando composer update drupal/[package_name]` to fetch/update only the desired module.

### Updating Contrib Modules

- `lando composer update drupal/[package_name]`

Sometimes several contrib modules are several versions behind.

*Do not use `lando composer update` without specifying a module, or it will update everything that's outdated at once, possibly introducing regressions which you'll have to do much more testing for.*

*Updates should be controlled and tested well. It's easiest to do that in smaller chunks. Especially watch out for BETA, ALPHA, or DEV versions of modules which are not stable and make no guarantees about not breaking things between updates.*

### Removing Contrib Modules

- `lando composer remove` will remove a package from require or require-dev.
- A clean build `lando build` of the codebase will delete contribs and vendor code and rebuild, without the removed modules.

### How can I apply patches to downloaded modules?

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


## To Deploy

_*If you're going to deploy, especially to production, make sure you understand how to configure, and what's happening during, the deploy process. It's great that we can automate things, but if you don't know what the machine is doing, you're going to panic or have a really hard time if something goes wrong.*_

_*Automation is a tool to make developers more efficient, not a replacement for knowledge and competency. Make sure a responsible adult is around to help.*_

**MAKE A BACKUP of CODE, FILES AND DATABASE before deploying TO PRODUCTION**

**You should have the working repo configured first. See above.**

- If you haven't already: Clone the PRODUCTION repo aka: the "build artifact" (from host i.e. pantheon) to `[project root]/data/_deploy`
    - From `[project root]` do:
        - `git clone [production git url] data/_deploy`

*Back in the working repo:*

- `git checkout [branch to deploy]` develop or staging/staging-[version].
- `lando build -y` - Clean composer install.
- `lando build:theme` IMPORTANT: Compiled theme assets like CSS and JS are not committed to the working repo they must be generated.
    - These compiled assets will be synced with the production repo during deploy.
- **Make sure you have Monkey Wrench v2.2**
    - `mw version` should show you `v2.2`
    - `mw version-set v2.2` - to switch to the correct version.
    - If either of those commands fail, you have an outdated MW.
        - Try `mw update-mw` to pull the latest code.
        - Then use the commands above to make sure you're on `v2.2`.
        - If `mw update-mw` doesn't do anything... you have a REALLY outdated MW, or no MW at all. Please see: [Monkey Wrench](https://bitbucket.org/cheekymonkeymedia/monkey-wrench/src/master/)
- `mw deploy [develop|stage|master] <version>`
    - This will sync the required elements from the local build to the production repo, commit and push to the host.

**Watch for errors in the sync and git push.**


### Troubleshooting Deploy:

#### Deployment Configuration Checklist

- Using proper mw version? `v2.2` projects will have a `scripts/deploy` file to configure details about the deploy for that project. `v1.5` projects will have a `deploy.ini` file.
- `v2.2` is your `scripts/deploy` file configured properly? If others can deploy the project without issue, then it likely is. If not, RTFM or ask a wise monkey for assitance.
- `v2.2` Have you cloned the build artifact (repo) to the default `data/_deploy` (or whatever path is configured in `scripts/deploy`)?

#### Other common issues _not related to `mw deploy`_

`lando build` or `lando build:theme` errors:

- `lando rebuild` to rebuild local containers.
- `lando destroy && lando start` because `lando rebuild` didn't help and you _*really*_ mean it this time.
- Restart Docker: because `lando destroy` didn't help and you just need to flush the system.
- NUKE VIRTUALIZATION TOOLS - Reinstall Lando, or Docker, or Both. *Obviously a last resort.* You shouldn't have to do this, unless maybe you updated one or the other recently and something isn't right.
- Flip Table (╯°□°）╯︵ ┻━┻  - Re-evaluate your life.
