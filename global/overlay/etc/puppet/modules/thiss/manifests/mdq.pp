class thiss::mdq($version="latest", $src=undef, $dst="/etc/thiss/metadata.json") {
   file {$dst:
      ensure   => 'present',
      replace  => 'no',
      content  => "[]",
      mode     => '0644'
   } ->
   file { '/usr/local/bin/get_metadata.sh': 
      contents     => template('mdq/get_metadata.sh'),
      owner        => root,
      group        => root,
      mode         => '0755'
   } ->
   sunet::scriptherder::cronjob { "${name}_fetch_metadata":
     cmd           => "/usr/local/bin/get_metadata.sh",
     minute        => '*/5',
     ok_criteria   => ['exit_status=0','max_age=48h'],
     warn_criteria => ['exit_status=1','max_age=50h'],
   } ->
   sunet::docker_run { "thiss_mdq":
      hostname => "${::fqdn}",
      image    => "docker.sunet.se/thiss-mdq",
      imagetag => $version,
      env      => ["METADATA=/etc/thiss/metadata.json","BASE_URL=https://md.thiss.io"],
      volumes  => ['/etc/thiss:/etc/thiss'],
      ports    => ['80:3000'],
      extra_parameters => ["--log-driver=syslog"]
   }
}
