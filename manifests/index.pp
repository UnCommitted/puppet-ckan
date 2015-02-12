# Configures CKAN Database 
#
# NOTE: This only currently works on UBUNTU.
class ckan::index (
  # Name of the collective CKAN Node (dev/prod/test)
  $ckan_node_id,
  $ckan_version
) {

  # Install and configure tomcat
  class { 'tomcat':
    install_from_source => false,
  }->

  package { [
      'solr-tomcat',
      'git'
    ]:
    ensure => 'installed'
  }->

  file {
    'core_properties_file':
      ensure  => 'present',
      path    => '/usr/share/solr/core.properties',
      content => template('ckan/index/core_properties_file.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => [
        Class['tomcat'],
        Package['solr-tomcat']
      ];

    'indexhost_solr_config_directory':
      ensure  => 'directory',
      path    => "/etc/tomcat6/Catalina/${::fqdn}",
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => Class['tomcat'];

    'indexhost_solr_config':
      ensure  => 'link',
      path    => "/etc/tomcat6/Catalina/${::fqdn}/solr.xml",
      target  => '/etc/solr/solr-tomcat.xml',
      require => File['indexhost_solr_config_directory'];

  }->

  # Download the appropriate version of the solr schema
  exec { 'download_solr_configuration':
    command  => "cd /usr/share/solr/collection1/conf && wget https://raw.githubusercontent.com/ckan/ckan/ckan-${ckan_version}/ckan/config/solr/schema.xml && chown tomcat.tomcat *.xml",
    provider => 'shell',
    creates  => '/usr/share/solr/collection1/conf/schema.xml',
    requires => Package['git'];
  }->

  # Actually start the service
  tomcat::instance{ 'default':
    package_name => 'tomcat6',
  }->

  tomcat::service { 'default':
    use_jsvc     => false,
    use_init     => true,
    service_name => 'tomcat6'
  }
}

# vim: set shiftwidth=2 softtabstop=2 textwidth=0 wrapmargin=0 syntax=ruby:

