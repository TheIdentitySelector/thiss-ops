class thiss::demo_sp($version='stable')
{
  ensure_resource('file','/var/www/html/', { ensure => directory } )

  sunet::docker_compose {'demo-sp':
    service_name => 'demo-sp',
    description  => 'SA demo sp',
    compose_dir  => '/opt/demo_sp/compose',
    content => template('thiss/demo_sp/demo_sp.yml.erb'),
  }

  vcsrepo { '/var/www/demo':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/TheIdentitySelector/thiss-demo'
  }
}
