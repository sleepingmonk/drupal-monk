## Local Development With Lando

* Docker: https://www.docker.com/community-edition
* Lando: https://docs.devwithlando.io

Once installed cd to project directory and type `lando` for a list of commands.

*Spin up the local:*

 - `lando start` - Spin up the environment.
 - `lando db-import [path to db]` - Import your database. Store db in `data/`.
 - `lando build -y` - Clean composer install.
 - `lando build:theme` - Build the theme assets.
 - `lando build:reset` - Runs reset.sh to updb, cim, cr ...

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

 - `lando composer remove [package] --no-update` will remove a package from require or require-dev, without running all updates.
 - `lando composer update [package]` will remove the package code.
 - A clean build `lando build -c` of the codebase will delete contribs and vendor code and rebuild, without the removed modules.

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

#### Troubleshooting common issues.

`lando build` or `lando build:theme` errors:

 - `lando restart` to restart the services.
 - `lando rebuild` to rebuild local containers if restart didn't help.
 - Restart Docker: because `lando rebuild` didn't help and you just need to flush the system.
 - `lando destroy && lando start` because Docker Restart didn't help and you _*really*_ mean it this time. (You will need to re-import databases.)
 - NUKE VIRTUALIZATION TOOLS - Reinstall Lando, or Docker, or Both. *Obviously a last resort.* You shouldn't have to do this, unless maybe you updated one or the other recently and something isn't right.
 - Flip Table (╯°□°）╯︵ ┻━┻  - Re-evaluate your life.

