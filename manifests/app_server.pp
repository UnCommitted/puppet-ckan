# Configures the CKAN App Server
class ckan::app_server (

  # Web Server Setup
  $site_url       = $::ckan::params::site_url,
  $server_aliases = $::ckan::params::server_aliases,

  # Hostname of the database server
  $index_hostname = $::ckan::params::index_hostname,

  $ckan_version   = $::ckan::params::ckan_version,
  $ckan_node_id   = $::ckan::params::ckan_node_id

) {

  # Install the CKAN softare
  contain '::ckan::ckan_software'

  # Apache and wsgi configuration
  class { 'apache':
    default_vhost => false,
  }

  contain '::apache::mod::wsgi'
  contain '::apache::mod::ssl'

  # Create some apache related directories
  file {
    '/var/www/ckan':
      ensure => 'directory',
      mode   => '0700',
      owner  => 'root',
      group  => 'root';

    "/var/www/ckan/${ckan_node_id}":
      ensure  => 'directory',
      mode    => '0700',
      owner   => 'root',
      group   => 'root',
      require => File['/var/www/ckan'];

    "/var/log/apache2/${site_url}_error_ssl.log":
      ensure  => 'present',
      mode    => '0640',
      owner   => 'root',
      group   => 'adm';
  }

  apache::vhost { "${site_url}":
    # General Configuration
    docroot                     => "/var/www/ckan/${ckan_node_id}",
    serveraliases               => $server_aliases,
    ip                          => $::ipaddress_eth0,
    ssl                         => true,
    port                        => '443',

    # WSGI Setup for CKAN
    wsgi_daemon_process         => "ckan_${ckan_node_id}",
    wsgi_daemon_process_options => {
      processes    => '2',
      threads      => '15',
      display-name => "ckan_${ckan_node_id}",
    },
    wsgi_process_group          => "ckan_${ckan_node_id}",
    wsgi_script_aliases         => {
      '/' => "/etc/ckan/${ckan_node_id}/apache-${ckan_node_id}.wsgi"
    },
    wsgi_chunked_request        => 'On',
    wsgi_pass_authorization     => 'On',
    require                     => File[
      "/var/www/ckan/${ckan_node_id}",
      "/var/log/apache2/${site_url}_error_ssl.log"
    ]
  }

  # Create directories
  file {

    # WSGI configuration
    "/etc/ckan/${ckan_node_id}/apache-${ckan_node_id}.wsgi":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('ckan/app/apache.wsgi.erb'),
      require => [
        File["/etc/ckan/${ckan_node_id}"],
      ];
  }

  file {
    # Make the wsgi configuration script executable by apache.
    'set_wsgi_script_to_executable':
      path   => "/var/lib/ckan/${ckan_node_id}/ckan/bin/activate_this.py",
      ensure => 'present',
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0755';
  }

}

# vim: set shiftwidth=2 softtabstop=2 textwidth=0 wrapmargin=0 syntax=ruby:

