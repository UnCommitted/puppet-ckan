# Install the ckan software for use by other processes
class ckan::ckan_software (
  $ckan_node_id          = $::ckan::params::ckan_node_id,
  $app_uuid              = $::ckan::params::app_uuid,
  $beaker_uuid           = $::ckan::params::beaker_uuid,
  $ckan_db_name          = $::ckan::params::ckan_db_name_real,
  $datastore_db_name     = $::ckan::params::datastore_db_name_real,
  $ckan_db_user          = $::ckan::params::ckan_db_user_real,
  $ckan_db_password      = $::ckan::params::ckan_db_password,
  $datastore_db_user     = $::ckan::params::datastore_db_user_real,
  $datastore_db_password = $::ckan::params::datastore_db_password,
  $db_hostname           = $::ckan::params::db_hostname,
  $ckan_version          = $::ckan::params::ckan_version,
  $ckan_user             = $::ckan::params::ckan_user,
  $ckan_group            = $::ckan::params::ckan_group,
  $index_hostname        = $::ckan::params::index_hostname,
) {

  Class['ckan::params']->Class['ckan::ckan_software']

  # Create the ckan user and groups
  group { 'ckan_group':
    name   => $ckan_group,
    ensure => 'present'
  }

  user { 'ckan_user':
    name       => $ckan_user,
    shell      => '/usr/sbin/nologin',
    home       => '/usr/lib/ckan',
    managehome => true,
    gid        => 'ckan',
    require    => Group['ckan_group'];
  }

  # Create directories
  file {
    [
      '/etc/ckan',
      '/var/lib/ckan'
    ]:
      ensure  => 'directory',
      owner   => 'ckan',
      group   => 'ckan',
      mode    => '0755',
      require => [
        User['ckan_user'],
        Group['ckan_group']
      ];

    "/etc/ckan/${ckan_node_id}":
      ensure  => 'directory',
      owner   => $ckan_user,
      group   => $ckan_group,
      mode    => '0755',
      require => [
        File['/etc/ckan'],
        User['ckan_user'],
        Group['ckan_group']
      ];

    "/var/lib/ckan/${ckan_node_id}":
      ensure  => 'directory',
      owner   => $ckan_user,
      group   => $ckan_group,
      mode    => '0755',
      require => [
        File['/var/lib/ckan'],
        User['ckan_user'],
        Group['ckan_group']
      ];

    # NOTE: Node CKAN configuration - there will need to be a
    # version of the template created for each version of ckan that is supported.
    "/etc/ckan/${ckan_node_id}/${ckan_node_id}.ini":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("ckan/ckan_software/node-${ckan_version}.ini.erb"),
      require => File["/var/lib/ckan/${ckan_node_id}"];
  }

  # Create new python virtual environment
  class { 'python' :
    virtualenv => true,
    dev        => true,
    gunicorn => false
  }

  python::virtualenv { "/var/lib/ckan/${ckan_node_id}/ckan" :
    ensure      => present,
    version     => 'system',
    systempkgs  => false,
    distribute  => false,
    owner       => $ckan_user,
    group       => $ckan_group,
    timeout     => 0,
    require     => [
      File["/var/lib/ckan/${ckan_node_id}"],
      User['ckan_user'],
      Group['ckan_group'],
      Class['python']
    ];
  }

  File <| title == "/var/lib/ckan/${ckan_node_id}/ckan" |> {
    mode => '0755'
  }

  # Clone CKAN Git Repository
  exec { 'clone_ckan':
    command  => "cd /var/lib/ckan/ && git clone https://github.com/ckan/ckan.git",
    creates  => "/var/lib/ckan/ckan",
    provider => 'shell',
    require  => Python::Virtualenv["/var/lib/ckan/${ckan_node_id}/ckan"];
  }

  exec { "install_ckan_${ckan_version}":
    command     => ". /var/lib/ckan/dev/ckan/bin/activate && cd /var/lib/ckan/ckan && git checkout ckan-${ckan_version} && pip install -r requirements.txt && python ./setup.py develop && python ./setup.py install",
    provider    => 'shell',
    refreshonly => true,
    timeout     => 0,
    subscribe   => Exec['clone_ckan'],
    require     => Python::Virtualenv["/var/lib/ckan/${ckan_node_id}/ckan"];
  }

  exec {
    # Get the ini file
    'get_ckan_ini_file':
      command     => "cp /var/lib/ckan/ckan/who.ini /etc/ckan/${ckan_node_id}/who.ini",
      provider    => 'shell',
      refreshonly => true,
      subscribe   => Exec["install_ckan_${ckan_version}"],
      require     => File["/etc/ckan/${ckan_node_id}"];
  }

}

# vim: set et shiftwidth=2 softtabstop=2 textwidth=0 wrapmargin=0 syntax=ruby:

