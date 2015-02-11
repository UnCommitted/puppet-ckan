# Configures the CKAN App Server
class ckan::app_server (
  $ckan_node_id,
) {

  # Required packages
  package {
    [
      'python-virtualenv',
      'python-pip',
      'libpq-dev',
    ]:
      ensure => 'installed';
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
  }
}

# vim: set shiftwidth=2 softtabstop=2 textwidth=0 wrapmargin=0 syntax=ruby:

