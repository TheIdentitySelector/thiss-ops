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

  vcsrepo { '/var/www/demoBeta':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/TheIdentitySelector/thiss-demoBeta'
  }

  ensure_resource('file','/var/www/demo/profiles/', { ensure => directory } )
  ensure_resource('file','/var/www/demoBeta/db/', { ensure => directory } )

  file { '/var/www/demoBeta/profiles/':
    ensure => link,
    target => '/var/www/demo/profiles/',
  }

  sunet::scriptherder::cronjob { "updateProfiles":
    cmd               => "/opt/scripts/updateProfiles.py",
    ok_criteria       => ['exit_status=0'],
    warn_criteria     => ['max_age=90m'],
    minute            => '5'
  }

  sunet::scriptherder::cronjob { "updateProfiles":
    cmd               => "/opt/scripts/updateDB.py",
    ok_criteria       => ['exit_status=0'],
    warn_criteria     => ['max_age=48h'],
    hour              => '3'
  }
}
