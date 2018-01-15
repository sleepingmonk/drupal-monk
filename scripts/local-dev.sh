#!/bin/bash

# Prep the site for local development after importing a db from production or elsewhere.
#
# This file can be committed to your repo so it's available for all devs.
# Place it in a scripts/ directory inside your project repo (BESIDE your web/ docroot).
#
# This provides defaults. Customize this script for your project as needed.
# At a minimum update the disable/enable modules lists below, for your project.

# Disable modules.
# Some modules should not be enabled for local development.
# Disable with `mw drush dis`. List modules alphabetically, one per line ending in \.
# echo
# echo -e "\033[33mDisabling production modules.\033[0m"
# mw drush pm-uninstall -y \
#

# Enable developer modules.
# Some modules should be enabled for local development.
# Enable with `mw drush en`. List modules alphabetically, one per line ending in \.
echo
echo -e "\033[33mEnabling developer modules.\033[0m"
mw drush en -y \
devel \
field_ui \
menu_ui \
views_ui \

# Run updates.
echo
echo -e "\033[33mRunning db updates.\033[0m"
mw drush updb -y

# # Revert Features
# echo
# echo -e "\033[33mReverting Features.\033[0m"
# mw drush fra -y

# Clear Caches
echo
echo -e "\033[33mClearing Caches.\033[0m"
mw drush cr

# Admin Login Link
echo
echo -e "\033[33mGenerating Login Link\033[0m"
mw drush uli
