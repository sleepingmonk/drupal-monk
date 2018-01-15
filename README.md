# Composer template for Drupal projects

## Local Development

For local development, please remember the following:
* Make sure `web/sites/default/services.local.yml` is in place. (see `mw copy`)
* Make sure `web/sites/default/settings.local.php` is in place. (see `mw copy`)
* Make sure `web/sites/default/settings.php` includes settings.local.php.
* Import your database. `mw dbi`
* Config Import and Clear Caches. `mw local-dev`

## Setup

* `git fetch && git checkout master` Checkout the current master branch (default is develop)
* `docker-compose up -d` from the project root.
* `mw copy settings [path to src/sites/default/]` Copy default local settings. Edit if needed.
* Copy the database dump (Should be pinned to project slack channel) to `[project]/data/master.sql`
  Make sure it's extracted and not .zip or .gz
* `mw composer . install` Build the project for local development.
* `mw dbi data/master.sql` Install the database file.
* `mw local-dev` Run local dev setup, including drush updb, cim, enable devel modules, generate login link.

If you run into any problems with the build ping @calvin in slack.

## Development

 - Move ticket to "in progress".
 - Make a `feature/[ticket-id]--short-description` branch from `master`.
 - Use composer (through Monkey Wrench), to install drupal modules.
    - `mw composer . require drupal/[module] --no-update` (adds to composer.json without updating all other modules)
    - `mw composer . update drupal/[module]` (installs/updates only the specified module, leaving composer.lock pretty clean)
 - Use Drupal Console (through Monkey Wrench), to scaffold modules, etc.
    - `mw drupal generate:module` (`mw drupal` is a work in progress. If it doesn't work ping Calvin.)

*Any configuration changes should be managed with `mw drush cex` and `mw drush cim`*

## Workflow

* Pull Request: `feature/123` -> `develop`
* Dev test on develop environment.
* Pull Request: `feature/123` -> `staging/staging-x.y.z`
* User Acceptance Test on stage environment.
* Deploy feature release to master (production) after UAT sign off.

For more info see workflow documentation.
[https://drive.google.com/drive/u/0/folders/0B7ReslZJkgRZNzdHQ0xMd1VCNTQ](https://drive.google.com/drive/u/0/folders/0B7ReslZJkgRZNzdHQ0xMd1VCNTQ)

## Deploy

`mw deploy` for more info.
This project deploy is set up for Monkey Wrench `v2.0`.
`mw version` to check version.
`mw update-mw` to fetch the latest.
`mw version-set` to set based on project need.

### If `mw update-mw` fails:

You will need to manually pull the latest monkey-wrench.

`cd` to the dir you cloned monkey-wrench to `git checkout master` then `git pull origin master`.
_If you don't know where that is, check your path or your aliases or search for `monkey-wrench`._

### If you have the latest Monkey Wrench and deploy fails:

Set the Monkey Wrench version to the required version `mw version-set [version]`.
If that works, It is strongly recommended you reconfigure this project to deploy using the latest methods.

If it still does not work, troubleshoot the best you can and ask for help on slack.

## FAQ

### Should I commit the contrib modules I download?

Composer recommends **no**. They provide [argumentation against but also
workrounds if a project decides to do it anyway](https://getcomposer.org/doc/faqs/should-i-commit-the-dependencies-in-my-vendor-directory.md).

### Should I commit the scaffolding files?

The [drupal-scaffold](https://github.com/drupal-composer/drupal-scaffold) plugin can download the scaffold files (like
index.php, update.php, …) to the web/ directory of your project. If you have not customized those files you could choose
to not check them into your version control system (e.g. git). If that is the case for your project it might be
convenient to automatically run the drupal-scaffold plugin after every install or update of your project. You can
achieve that by registering `@drupal-scaffold` as post-install and post-update command in your composer.json:

```json
"scripts": {
    "drupal-scaffold": "DrupalComposer\\DrupalScaffold\\Plugin::scaffold",
    "post-install-cmd": [
        "@drupal-scaffold",
        "..."
    ],
    "post-update-cmd": [
        "@drupal-scaffold",
        "..."
    ]
},
```
### How can I apply patches to downloaded modules?

If you need to apply patches (depending on the project being modified, a pull
request is often a better solution), you can do so with the
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
### How do I switch from packagist.drupal-composer.org to packages.drupal.org?

Follow the instructions in the [documentation on drupal.org](https://www.drupal.org/docs/develop/using-composer/using-packagesdrupalorg).
