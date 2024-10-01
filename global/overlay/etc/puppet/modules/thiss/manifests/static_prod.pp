class thiss::static_prod($ds_version="latest",
                      $base_url=undef,
                      $mdq_search_url=undef,
                      $domain=undef,
                      $context=undef,
                      $mdq_hostport=undef,
                      $cache_control=undef) {

   $final_mdq_search_url = $mdq_search_url ? {
    undef   => chop($base_url)/entities,
    default => $mdq_search_url,
   }
   $component_url=chop($base_url)
   $persistence_url=chop($base_url)
   $whitelist = hiera ('whitelist')

   sunet::snippets::somaxconn { "ds_nginx": maxconn => 4096 }
   if $mdq_hostport {
    $mdq_search_url=chop($base_url)
    sunet::docker_run { "thiss_js":
      hostname => "${::fqdn}",
      image    => "docker.sunet.se/thiss-js",
      imagetag => $ds_version,
      env      => ["BASE_URL=$base_url",
                   "MDQ_URL=$final_mdq_search_url",
                   "SEARCH_URL=$final_mdq_search_url",
                   "STORAGE_DOMAIN=$domain",
                   "LOGLEVEL=warn",
                   "DEFAULT_CONTEXT=$context",
                   "MDQ_HOSTPORT=$mdq_hostport",
                   "COMPONENT_URL=$component_url/cta/",
                   "PERSISTENCE_URL=$persistence_url/ps/",
                   "CACHE_CONTROL=\"$cache_control\"",
                   "WHITELIST=$whitelist"],
      volumes  => ["/etc/ssl:/etc/ssl"],
      ports    => ["80:80"],
      extra_parameters => ["--log-driver=syslog"]
    }
   }
  else {
    sunet::docker_run { "thiss_js":
      hostname => "${::fqdn}",
      image    => "docker.sunet.se/thiss-js",
      imagetag => $ds_version,
      env      => ["BASE_URL=$base_url",
                   "MDQ_URL=$final_mdq_search_url",
                   "SEARCH_URL=$final_mdq_search_url",
                   "STORAGE_DOMAIN=$domain",
                   "LOGLEVEL=warn",
                   "DEFAULT_CONTEXT=$context",
                   "COMPONENT_URL=$component_url/cta/",
                   "PERSISTENCE_URL=$persistence_url/ps/",
                   "CACHE_CONTROL=\"$cache_control\"",
                   "WHITELIST=$whitelist"],
      volumes  => ["/etc/ssl:/etc/ssl"],
      ports    => ["80:80"],
      extra_parameters => ["--log-driver=syslog"]
    }
  }
}
