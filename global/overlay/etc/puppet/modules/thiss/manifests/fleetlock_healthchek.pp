class thiss::fleetlock_helathcheck{

  file { '/etc/sunet-machine-healthy':
    ensure => directory,
  }
  -> file { '/etc/sunet-machine-healthy/health-checks.d':
      ensure => directory,
     }

  if $facts['networking']['fqdn'] =~ /^static\./ {
    file { '/etc/sunet-machine-healthy/health-checks.d/check_haproxy.check':
      ensure  => file,
      content => template("thiss/fleetlock_reboot/check_haproxy.check.erb"),
      mode    => '0744',
    }
  } elsif $facts['networking']['fqdn'] !~ /^meta\./ {
    file { '/etc/sunet-machine-healthy/health-checks.d/check_web.check':
      ensure  => file,
      content => template("thiss/fleetlock_reboot/check_web.check.erb"),
      mode    => '0744',
    }
  }
}