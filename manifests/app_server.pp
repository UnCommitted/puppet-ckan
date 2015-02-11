# Configures the CKAN App Server
class ckan::app_server (
  $ckan_node_id,
) {
  
  # Create the ckan user and groups
  group { 'ckan_group':
    name   => 'ckan',
    ensure => 'present'
  }

  user { 'ckan_user':
    name           => 'ckan',
    shell          => '/usr/sbin/nologin',
    home           => '/usr/lib/ckan',
    managehome     => true,
    gid            => 'ckan',
    require        => Group['ckan_group'];
  }
}

# vim: set shiftwidth=2 softtabstop=2 textwidth=0 wrapmargin=0 syntax=ruby:

