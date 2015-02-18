# Configures CKAN Database Server
class ckan::database (
  # Name of the collective CKAN Node (dev/prod/test)
  $ckan_node_id          = $::ckan::params::ckan_node_id,
  $ckan_db_name          = $::ckan::params::ckan_db_name_real,
  $datastore_db_name     = $::ckan::params::datastore_db_name_real,
  $ckan_db_user          = $::ckan::params::ckan_db_user_real,
  $ckan_db_password      = $::ckan::params::ckan_db_password,
  $datastore_db_user     = $::ckan::params::datastore_db_user_real,
  $datastore_db_password = $::ckan::params::datastore_db_password,
  $postgres_password     = $::ckan::params::postgres_password,

  # IP Address of the CKAN App Server
  $ckan_app_ip           = $::ckan::params::ckan_app_ip,

  # Database encoding
  $db_encoding           = $::ckan::params::db_encoding

) {

  # I require params to be instantiated first
  Class['ckan::params'] -> Class['ckan::database']

  # Make sure software is installed.
  contain '::ckan::ckan_software'

  # Postgresql installation.
  class { '::postgresql::server':
    postgres_password => "${postgres_password}",
    listen_addresses  => '*',
    ipv4acls          => [
      "host ${ckan_db_name} ${ckan_db_user} ${ckan_app_ip}/32 md5",
      "host ${datastore_db_name} ${ckan_db_user} ${ckan_app_ip}/32 md5",
      "host ${datastore_db_name} ${datastore_db_user} ${ckan_app_ip}/32 md5",
      "host ${ckan_db_name} ${ckan_db_user} ${::ipaddress_eth0}/32 md5",
      "host ${datastore_db_name} ${ckan_db_user} ${::ipaddress_eth0}/32 md5",
      "host ${datastore_db_name} ${datastore_db_user} ${::ipaddress_eth0}/32 md5",
      "host root root ${::ipaddress_eth0}/32 md5",
    ]
  }

  contain '::postgresql::server'

  # Configure ckan databases
  ::postgresql::server::db {

    # CKAN Database
    "${ckan_db_name}":
      user     => "${ckan_db_user}",
      encoding => "${db_encoding}",
      password => postgresql_password(
        "${ckan_db_user}",
        "${ckan_db_password}"
      );

    # Datastore Database
    "${datastore_db_name}":
      user     => "${datastore_db_user}",
      encoding => "${db_encoding}",
      password => postgresql_password(
        "${datastore_db_user}",
        "${datastore_db_password}"
      );
  }

  # Allow ckan and datastore user to access the other tables
  postgresql::server::database_grant {
    "${ckan_db_name}_${datastore_db_user}":
      privilege => 'ALL',
      db        => "${ckan_db_name}",
      role      => "${datastore_db_user}";

    "${ckan_db_name}_${ckan_db_user}":
      privilege => 'ALL',
      db        => "${ckan_db_name}",
      role      => "${ckan_db_user}";

    "${datastore_db_name}_${ckan_db_user}":
      privilege => 'ALL',
      db        => "${datastore_db_name}",
      role      => "${ckan_db_user}";

    "${datastore_db_name}_${datastore_db_user}":
      privilege => 'ALL',
      db        => "${datastore_db_name}",
      role      => "${datastore_db_user}";
  }->

  exec {
    'initialize_ckan_db':
      command     => ". /var/lib/ckan/${ckan_node_id}/ckan/bin/activate && paster --plugin=ckan db init -c /etc/ckan/${ckan_node_id}/${ckan_node_id}.ini",
      provider    => 'shell',
      subscribe   => Exec["get_ckan_ini_file"],
      require     => Class[
        '::ckan::ckan_software',
        '::postgresql::server'
      ],
      user        => 'ckan',
      refreshonly => true;
  }->

  exec {
    'initialize_datastore_db':
      command     => ". /var/lib/ckan/${ckan_node_id}/ckan/bin/activate && paster --plugin=ckan datastore set-permissions -c /etc/ckan/${ckan_node_id}/${ckan_node_id}.ini | sudo -u postgres psql",
      provider    => 'shell',
      subscribe   => Exec["get_ckan_ini_file"],
      require     => Class[
        '::ckan::ckan_software',
        '::postgresql::server'
      ],
      user        => 'root',
      refreshonly => true;
  }

}

# vim: set shiftwidth=2 softtabstop=2 textwidth=0 wrapmargin=0 syntax=ruby:

