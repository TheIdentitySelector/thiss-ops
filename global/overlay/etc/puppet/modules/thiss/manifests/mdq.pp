class thiss::mdq($version="latest", $src=undef) {
   file {"/etc/thiss/metadata.json":
      ensure   => 'present',
      replace  => 'no',
      content  => "[]",
      mode     => '0644'
   } ->
   sunet::scriptherder::cronjob { "${name}_fetch_metadata":
     cmd           => "rm -f /etc/thiss/metadata.json.new && wget -qO/etc/thiss/metadata.json.new $src && test -s /etc/thiss/metadata.json.new && mv /etc/thiss/metadata.json.new /etc/thiss/metadata.json",
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
