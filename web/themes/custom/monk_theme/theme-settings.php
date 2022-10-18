<?php

/**
 * @file
 * Theme settings form for Monk theme.
 */

/**
 * Implements hook_form_system_theme_settings_alter().
 */
function monk_theme_form_system_theme_settings_alter(&$form, &$form_state) {

  $form['monk_theme'] = [
    '#type' => 'details',
    '#title' => t('Monk'),
    '#open' => TRUE,
  ];

}
