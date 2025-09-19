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

  ensure_resource('file','/opt/static', { ensure => directory } )
  ensure_resource('file','/opt/static/compose', { ensure => directory } )

  sunet::docker_compose {'thiss-js':
    service_name => 'thiss_js',
    description  => 'SA identity selector software',
    compose_dir  => '/opt/static/compose',
    content => template('thiss/static/thiss-js_prod.yml.erb'),
  }

  sunet::nagios::nrpe_command {"check_sa_version":
    command_line => "/usr/lib/nagios/plugins/check_http -H localhost -u http://localhost/manifest.json -s ${ds_version_prod}"
  }
}
