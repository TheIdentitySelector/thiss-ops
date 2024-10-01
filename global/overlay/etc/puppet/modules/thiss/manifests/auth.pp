class thiss::auth($version="latest", $mdq_server=undef, $base_url=undef, $test_mode="false") {

   $final_base_url = "BASE_URL=${base_url}"
   $final_aud = "AUDIENCE=${base_url}"
 
   ensure_resource('file','/etc/thiss/', { ensure => directory } )

   sunet::docker_run { "thiss_auth":
      hostname => "${::fqdn}",
      image    => "docker.sunet.se/thiss-auth",
      imagetag => $version,
      env      => ["MDQ_SERVER=${mdq_server}","KEYSTORE=/etc/thiss/keystore.jwks", "${final_base_url}", "${final_aud}", "TEST_MODE=${test_mode}"],
      volumes  => ['/etc/thiss:/etc/thiss'],
      ports    => ['80:3000'],
      extra_parameters => ["--log-driver=syslog"]
   }
}

