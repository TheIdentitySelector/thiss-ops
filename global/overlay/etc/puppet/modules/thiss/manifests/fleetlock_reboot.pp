class thiss::fleetlock_reboot(
  String $fleetlock_group,
  String $fleetlock_server,
){

  $content = "fleetlock_group=${fleetlock_group}"
  file { '/etc/run-cosmos-fleetlock-conf':
    ensure  => file,
    content => $content,
  }

  $password = safe_hiera('fleetlock_password', [])

  $content2 = "[${fleetlock_group}]
server = ${fleetlock_server}
password = ${password}"

  file { '/etc/sunet-fleetlock/':
    ensure => directory,
  }
  -> file { '/etc/sunet-fleetlock/sunet-fleetlock.conf':
      ensure  => file,
      content => $content2,
     }

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

