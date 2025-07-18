class thiss::static_prod($base_url=undef,
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
  $whitelist = hiera ('whitelist')
  $ds_version_prod = hiera ('ds_version_prod')
  $cache_control_prod = hiera ('cache_control_prod')

  sunet::snippets::somaxconn { "ds_nginx": maxconn => 4096 }

  if $::facts['dockerhost2'] == 'yes' {

    ensure_resource('file','/opt/static', { ensure => directory } )
    ensure_resource('file','/opt/static/compose', { ensure => directory } )

    sunet::docker_compose {'thiss-js':
      service_name => 'thiss_js',
      description  => 'SA identity selector software',
      compose_dir  => '/opt/static/compose',
      content => template('thiss/static/thiss-js.yml.erb'),
    }
  }
  else {
    if $mdq_hostport {
      $mdq_search_url=chop($base_url) #not in docker-compose section, unclear why it is here
      sunet::docker_run { "thiss_js":
        hostname => $facts['networking']['fqdn'],
        image    => "docker.sunet.se/thiss-js",
        imagetag => $ds_version_prod,
        env      => ["BASE_URL=$base_url",
                     "MDQ_URL=$final_mdq_search_url",
                     "SEARCH_URL=$final_mdq_search_url",
                     "STORAGE_DOMAIN=$domain",
                     "LOGLEVEL=warn",
                     "DEFAULT_CONTEXT=$context",
                     "MDQ_HOSTPORT=$mdq_hostport",
                     "COMPONENT_URL=$component_url/cta/",
                     "PERSISTENCE_URL=$persistence_url/ps/",
                     "CACHE_CONTROL=\"$cache_control_prod\"",
                     "WHITELIST=$whitelist"],
        volumes  => ["/etc/ssl:/etc/ssl"],
        ports    => ["80:80"],
        extra_parameters => ["--log-driver=syslog"]
    }
  }
    else {
      sunet::docker_run { "thiss_js":
        hostname => $facts['networking']['fqdn'],
        image    => "docker.sunet.se/thiss-js",
        imagetag => $ds_version_prod,
        env      => ["BASE_URL=$base_url",
                     "MDQ_URL=$final_mdq_search_url",
                     "SEARCH_URL=$final_mdq_search_url",
                     "STORAGE_DOMAIN=$domain",
                     "LOGLEVEL=warn",
                     "DEFAULT_CONTEXT=$context",
                     "COMPONENT_URL=$component_url/cta/",
                     "PERSISTENCE_URL=$persistence_url/ps/",
                     "CACHE_CONTROL=\"$cache_control_prod\"",
                     "WHITELIST=$whitelist"],
        volumes  => ["/etc/ssl:/etc/ssl"],
        ports    => ["80:80"],
        extra_parameters => ["--log-driver=syslog"]
      }
    }
  }

  sunet::nagios::nrpe_command {"check_sa_version":
    command_line => "/usr/lib/nagios/plugins/check_http -H localhost -u http://localhost/manifest.json -s ${ds_version_prod}"
  }
}
