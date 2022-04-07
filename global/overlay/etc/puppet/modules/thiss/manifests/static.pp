class thiss::static($ds_version="latest",
                      $base_url=undef,
                      $mdq_search_url=undef,
                      $domain=undef,
                      $context=undef,
                      $mdq_hostport=undef) {

   $final_mdq_search_url = $mdq_search_url ? {
    undef   => chop($base_url)/entities,
    default => $mdq_search_url,
   }
   $component_url=chop($base_url)
   $persistence_url=chop($base_url)

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
                   'CACHE_CONTROL="public, max-age=3600, must-revalidate, s-maxage=3600, proxy-revalidate"'],
      volumes  => ["/etc/ssl:/etc/ssl"],
      ports    => ["443:443"],
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
                   'CACHE_CONTROL="public, max-age=3600, must-revalidate, s-maxage=3600, proxy-revalidate"'],
      volumes  => ["/etc/ssl:/etc/ssl"],
      ports    => ["80:80"],
      extra_parameters => ["--log-driver=syslog"]
    }
  }
}
