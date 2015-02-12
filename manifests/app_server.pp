# Configures the CKAN App Server
class ckan::app_server (
  $ckan_node_id,

  # Generate each of these with a separate uuid
  $app_uuid,
  $beaker_uuid,

  # Database names
  $ckan_db_name          = undef,
  $datastore_db_name     = undef,

  # Username and password for the CKAN Database
  $ckan_db_user          = undef,
  $ckan_db_password,

  # Username and password for the DATASTORE Database
  $datastore_db_user     = undef,
  $datastore_db_password,

  # Hostname to get to the database server
  $db_hostname,

  # Hostname of the database server
  $index_hostname,

  # This can be changed, but a new node.ini template
  # will need to be added
  $ckan_version          = '2.2.1',
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

  # Create the ckan user and groups
  group { 'ckan_group':
    name   => 'ckan',
    ensure => 'present'
  }

  user { 'ckan_user':
    name       => 'ckan',
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
      owner   => 'ckan',
      group   => 'ckan',
      mode    => '0755',
      require => [
        File['/etc/ckan'],
        User['ckan_user'],
        Group['ckan_group']
      ];

    "/var/lib/ckan/${ckan_node_id}":
      ensure  => 'directory',
      owner   => 'ckan',
      group   => 'ckan',
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
      content => template("ckan/app/node-${ckan_version}.ini.erb"),
      require => File["/var/lib/ckan/${ckan_node_id}"];
  }

  # Create new python virtual environment
  class { 'python' :
    virtualenv => true,
    dev        => true,
    gunicorn => false
  }

  python::virtualenv { "/var/lib/ckan/${ckan_node_id}/ckan" :
    ensure     => present,
    version    => 'system',
    systempkgs => false,
    distribute => false,
    owner      => 'ckan',
    group      => 'ckan',
    timeout    => 0,
    require    => [
      User['ckan'],
      Group['ckan'],
      File["/var/lib/ckan/${ckan_node_id}"],
      Class['python']
    ];
  }

  # Install CKAN
  python::pip { 'ckan' :
    pkgname    => 'git+https://github.com/ckan/ckan.git@ckan-2.2.1#egg=ckan',
    ensure     => 'present',
    virtualenv => "/var/lib/ckan/${ckan_node_id}/ckan",
    owner      => 'ckan',
    timeout    => 0,
    require    => Python::Virtualenv["/var/lib/ckan/${ckan_node_id}/ckan"];
   }

  # Get the requirements file
  exec { 'get_requirements_file':
    command  => "cd /var/lib/ckan/${ckan_node_id} && wget https://raw.githubusercontent.com/ckan/ckan/ckan-${ckan_version}/requirements.txt",
    creates  => "/var/lib/ckan/${ckan_node_id}/requirements.txt",
    provider => 'shell',
    require  => File["/var/lib/ckan/${ckan_node_id}"];
  }

  # Install requirements
  python::requirements { "/var/lib/ckan/${ckan_node_id}/requirements.txt" :
    virtualenv => "/var/lib/ckan/${ckan_node_id}/ckan",
    owner      => 'ckan',
    group      => 'ckan',
    require    => [
      Python::Pip['ckan'],
      Exec['get_requirements_file']
    ];
  }

  exec {
    # Get the ini file
    'get_ckan_ini_file':
      command  => "cd /etc/ckan/${ckan_node_id} && wget https://raw.githubusercontent.com/ckan/ckan/ckan-${ckan_version}/ckan/config/who.ini",
      creates  => "/etc/ckan/${ckan_node_id}/who.ini",
      provider => 'shell',
      require  => File["/etc/ckan/${ckan_node_id}"];
  }


}

# vim: set shiftwidth=2 softtabstop=2 textwidth=0 wrapmargin=0 syntax=ruby:

