class thiss::mdq($version="latest", $src=undef, $dst="/etc/thiss/metadata.json", $base_url=undef) {

   $final_base_url = "BASE_URL=${base_url}"

   ensure_resource('file','/etc/thiss/', { ensure => directory } )

   file {$dst:
      ensure   => 'present',
      replace  => 'no',
      content  => "[]",
      mode     => '0644'
   } ->
   file { '/usr/local/bin/get_metadata.sh': 
      content      => template('thiss/mdq/get_metadata.erb'),
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
      env      => ["METADATA=/etc/thiss/metadata.json","${final_base_url}"],
      volumes  => ['/etc/thiss:/etc/thiss'],
      ports    => ['80:3000'],
      extra_parameters => ["--log-driver=syslog"]
   }
}
