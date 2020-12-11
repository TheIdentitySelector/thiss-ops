class thiss::thiss_js($ds_version="latest",
                      $base_url=undef,
                      $domain=undef,
                      $context=undef,
                      $whitelist=undef,
                      $mdq_hostport=undef) {

   sunet::snippets::somaxconn { "ds_nginx": maxconn => 4096 }
   sunet::docker_run { "thiss_js":
      hostname => "${::fqdn}",
      image    => "docker.sunet.se/thiss-js",
      imagetag => $ds_version,
      env      => ["BASE_URL=$base_url/",
                   "MDQ_URL=$base_url/entities/",
                   "SEARCH_URL=$base_url/entities",
                   "STORAGE_DOMAIN=$domain",
                   "LOGLEVEL=warn",
                   "DEFAULT_CONTEXT=$context",
                   "MDQ_HOSTPORT=$mdq_hostport",
                   "WHITELIST=$whitelist",
                   "TLS_KEY=/etc/ssl/private/${::fqdn}_infra.key",
                   "TLS_CERT=/etc/ssl/certs/${::fqdn}_infra.crt"],
      volumes  => ["/etc/ssl:/etc/ssl"],
      ports    => ["443:443"],
      extra_parameters => ["--log-driver=syslog"]
   }
}
