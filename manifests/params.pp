# CKAN Installation Parameters and defaults
class ckan::params (
  ###############################
  ## CKAN APPLICATION SETTINGS ##
  ###############################

  # Name of the collective CKAN Node (dev/prod/test)
  $ckan_node_id,

  # IP Address of the CKAN App Server
  $ckan_version          = '2.3',

  # Application uuids that need to be generated
  $app_uuid,
  $beaker_uuid,

  #################################
  ## APPLICATION SERVER SETTINGS ##
  #################################
  $ckan_app_ip,
  $site_url,
  $server_aliases = [],

  ###########################
  ## INDEX SERVER SETTINGS ##
  ###########################
  $index_hostname,

  ##############################
  ## DATABASE SERVER SETTINGS ##
  ##############################

  # Name of the database host
  $db_hostname,

  # CKAN Database Settings
  $ckan_db_name          = undef,
  $ckan_db_user          = undef,
  $ckan_db_password,

  # DATASTORE Database Settings
  $datastore_db_name     = undef,
  $datastore_db_user     = undef,
  $datastore_db_password,

  # Root password for the database server
  $postgres_password,

  ####################################
  ## MISCELLANEOUS DEFAULT SETTINGS ##
  ####################################

  # CKAN user and group names.
  $ckan_user             = 'ckan',
  $ckan_group            = 'ckan',

  # Database encoding
  $db_encoding           = 'utf-8'

) {

  # Set some saner defaults based on the node id
  if $ckan_db_name == undef {
    $ckan_db_name_real = "ckan_${ckan_node_id}"
  } else {
    $ckan_db_name_real = $ckan_db_name
  }

  if $datastore_db_name == undef {
    $datastore_db_name_real = "datastore_${ckan_node_id}"
  } else {
    $datastore_db_name_real = $datastore_db_name
  }

  if $ckan_db_user == undef {
    $ckan_db_user_real = "ckan_${ckan_node_id}"
  } else {
    $ckan_db_user_real = $ckan_db_user
  }

  if $datastore_db_user == undef {
    $datastore_db_user_real = "datastore_${ckan_node_id}"
  } else {
    $datastore_db_user_real = $datastore_db_user
  }
}

# vim: set shiftwidth=2 softtabstop=2 textwidth=0 wrapmargin=0 syntax=ruby:


