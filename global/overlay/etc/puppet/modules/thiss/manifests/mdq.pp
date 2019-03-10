class thiss::mdq($version="latest") {
   file {"/etc/thiss/metadata.json":
      ensure   => 'present',
      replace  => 'no',
      content  => "[]",
      mode     => '0644'
   } ->
   sunet::docker_run { "thiss_mdq":
      hostname => "${::fqdn}",
      image    => "docker.sunet.se/thiss-mdq",
      imagetag => $version,
      volumes  => ['/etc/thiss:/etc/thiss'],
      ports    => ['80:3000'],
      extra_parameters => ["--log-driver=syslog"]
   }
}
