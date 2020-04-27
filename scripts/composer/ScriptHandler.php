<?php

/**
 * @file
 * Contains \DrupalProject\composer\ScriptHandler.
 */

namespace DrupalProject\composer;

use Composer\Script\Event;
use Composer\Semver\Comparator;
use DrupalFinder\DrupalFinder;
use Symfony\Component\Filesystem\Filesystem;
use Symfony\Component\Finder\Finder;
use Webmozart\PathUtil\Path;

class ScriptHandler {

  public static function createRequiredFiles(Event $event) {
    $fs = new Filesystem();
    $drupalFinder = new DrupalFinder();
    $drupalFinder->locateRoot(getcwd());
    $drupalRoot = $drupalFinder->getDrupalRoot();

    $dirs = [
      'modules',
      'profiles',
      'themes',
    ];

    // Required for unit testing
    foreach ($dirs as $dir) {
      if (!$fs->exists($drupalRoot . '/'. $dir)) {
        $fs->mkdir($drupalRoot . '/'. $dir);
        $fs->touch($drupalRoot . '/'. $dir . '/.gitkeep');
      }
    }

    // Prepare the settings file for installation
    if (!$fs->exists($drupalRoot . '/sites/default/settings.php') and $fs->exists($drupalRoot . '/sites/default/default.settings.php')) {
      $fs->copy($drupalRoot . '/sites/default/default.settings.php', $drupalRoot . '/sites/default/settings.php');
      require_once $drupalRoot . '/core/includes/bootstrap.inc';
      require_once $drupalRoot . '/core/includes/install.inc';
      $settings['config_directories'] = [
        CONFIG_SYNC_DIRECTORY => (object) [
          'value' => Path::makeRelative($drupalFinder->getComposerRoot() . '/config', $drupalRoot),
          'required' => TRUE,
        ],
      ];
      drupal_rewrite_settings($settings, $drupalRoot . '/sites/default/settings.php');
      $fs->chmod($drupalRoot . '/sites/default/settings.php', 0666);
      $event->getIO()->write("Create a sites/default/settings.php file with chmod 0666");
    }

    // Create the files directory with chmod 0777
    if (!$fs->exists($drupalRoot . '/sites/default/files')) {
      $oldmask = umask(0);
      $fs->mkdir($drupalRoot . '/sites/default/files', 0777);
      umask($oldmask);
      $event->getIO()->write("Create a sites/default/files directory with chmod 0777");
    }
  }

  /**
   * Checks if the installed version of Composer is compatible.
   *
   * Composer 1.0.0 and higher consider a `composer install` without having a
   * lock file present as equal to `composer update`. We do not ship with a lock
   * file to avoid merge conflicts downstream, meaning that if a project is
   * installed with an older version of Composer the scaffolding of Drupal will
   * not be triggered. We check this here instead of in drupal-scaffold to be
   * able to give immediate feedback to the end user, rather than failing the
   * installation after going through the lengthy process of compiling and
   * downloading the Composer dependencies.
   *
   * @see https://github.com/composer/composer/pull/5035
   */
  public static function checkComposerVersion(Event $event) {
    $composer = $event->getComposer();
    $io = $event->getIO();

    $version = $composer::VERSION;

    // The dev-channel of composer uses the git revision as version number,
    // try to the branch alias instead.
    if (preg_match('/^[0-9a-f]{40}$/i', $version)) {
      $version = $composer::BRANCH_ALIAS_VERSION;
    }

    // If Composer is installed through git we have no easy way to determine if
    // it is new enough, just display a warning.
    if ($version === '@package_version@' || $version === '@package_branch_alias_version@') {
      $io->writeError('<warning>You are running a development version of Composer. If you experience problems, please update Composer to the latest stable version.</warning>');
    }
    elseif (Comparator::lessThan($version, '1.0.0')) {
      $io->writeError('<error>Drupal-project requires Composer version 1.0.0 or higher. Please update your Composer before continuing</error>.');
      exit(1);
    }
  }

  /**
   * Check if this repo is the working repo.
   *
   * Do not install if developer has checked out the build artifact rather than
   * the working repo.
   */
  public static function checkRepo(Event $event) {
    $extra = $event->getComposer()->getPackage()->getExtra();
    $working_repo = !empty($extra['working-repo']) ? $extra['working-repo'] : NULL;
    $origin = exec("git remote get-url origin");
    if (!empty($working_repo) && $origin != $working_repo) {
      echo "\n\n\e[33mWORKING REPO WARNING!\e[0m \n";
      echo "\n\e[31m$origin\e[0m \ndoes not appear to be the working repo.";
      echo "\nUse this for local development: \n\e[32m$working_repo\e[0m";
      echo "\nLocal work should done on the working repo from github. You may have checked out a build artifact from a host.\n";
      echo "\nPlease see the project README.md for workflow and deployment process.\nSee composer.json extra:working-repo\n";
      exit(1);
    }
  }

  /**
   * Post install tasks.
   * @param  Event  $event
   *  Composer script event.
   */
  public static function postInstall(Event $event) {
    $fs = new Filesystem();
    $finder = new Finder();
    $drupalFinder = new DrupalFinder();
    $drupalFinder->locateRoot(getcwd());
    $drupalRoot = $drupalFinder->getDrupalRoot();
    $composerRoot = $drupalFinder->getComposerRoot();

    // Don't create .lando.yml if one exists. Check 2 dirs up for scenarios
    // that build into a tmp directory and move back into lando directory.
    if (!$fs->exists($drupalRoot . '/../.lando.yml') && !$fs->exists($drupalRoot . '/../../.lando.yml')) {
      $fs->rename($drupalRoot . '/../start.lando.yml', $drupalRoot . '/../.lando.yml');
    }
    else {
      $fs->remove($drupalRoot . '/../start.lando.yml');
    }

    // Move settings.local.php files if necessary.
    // Get site dirs.
    $finder->depth('== 0');
    $finder->directories()->in($drupalRoot . '/sites');
    $copy_files = ['settings.local.php', 'services.local.yml', 'settings.php'];

    foreach ($finder as $dir) {
      $site = str_replace($drupalRoot . '/sites/', '', $dir);
      foreach ($copy_files as $copy_file) {
        if ($fs->exists("$composerRoot/scripts/local/$site/$copy_file") && !$fs->exists("$dir/$copy_file")) {
          $fs->copy("$composerRoot/scripts/local/$site/$copy_file", "$dir/$copy_file");
          echo "\n$copy_file was copied to $dir from scripts/local/$site\n";
          echo "This *SHOULD* get you started. Review $dir/$copy_file if you're having trouble.\n";
        }
      }
      echo "\nYou *MAY* find a starter sql file here: 'scripts/local/$site/sql.start' that you can import directly if you need it.\n";

    }

    echo "\n
SUCCESS!  You have installed your Drupal 8 Project!
See README.md for important information.\n
";
  }

}
