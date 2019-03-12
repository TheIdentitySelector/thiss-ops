
define thiss::nagios::check_mdq_health ($url=undef) {
   $mdq_url = $url ? {
      undef   => $title,
      default => $url
   }
   ensure_resource('file', '/usr/lib/nagios/plugins/check_mdq_health', {
      ensure  => 'file',
      mode    => '0555',
      group   => 'nagios',
      require => Package['nagios-nrpe-server'],
      content => template('thiss/mdq/check_mdq_health.erb'),
   })
   ensure_resource('nagioscfg::command','check_mdq_health', {
      command_line => "/usr/lib/nagios/plugins/check_mdq_health '\$HOSTNAME\'"
   })
   nagioscfg::service {"check_mdq_health_${name}":
      host_name     => [$name],
      check_command => "check_mdq_health",
      description   => "Check MDQ health at $name"
   }
}
