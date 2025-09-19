class thiss::fleetlock_healthcheck{

  file { '/etc/sunet-machine-healthy':
    ensure => directory,
  }
  -> file { '/etc/sunet-machine-healthy/health-checks.d':
      ensure => directory,
     }

  if $facts['networking']['fqdn'] =~ /^static\./ or $facts['networking']['fqdn'] =~ /^md\./ {
    file { '/etc/sunet-machine-healthy/health-checks.d/check_web_ssl.check.check':
      ensure  => file,
      content => template("thiss/fleetlock_healthcheck/check_web_ssl.check.erb"),
      mode    => '0744',
    }
    file { '/etc/sunet-machine-healthy/health-checks.d/check_haproxy.check':
      ensure  => file,
      content => template("thiss/fleetlock_healthcheck/check_haproxy.check.erb"),
      mode    => '0744',
    }
  } elsif $facts['networking']['fqdn'] !~ /^meta\./ {
    file { '/etc/sunet-machine-healthy/health-checks.d/check_web.check':
      ensure  => file,
      content => template("thiss/fleetlock_healthcheck/check_web.check.erb"),
      mode    => '0744',
    }
  }
}