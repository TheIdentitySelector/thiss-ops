class thiss::static_beta($base_url=undef,
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
  $ds_version_beta = hiera ('ds_version_beta')
  $cache_control_beta = hiera ('cache_control_beta')

  sunet::snippets::somaxconn { "ds_nginx": maxconn => 4096 }

  ensure_resource('file','/opt/static', { ensure => directory } )
  ensure_resource('file','/opt/static/compose', { ensure => directory } )

  sunet::docker_compose {'thiss-js':
    service_name => 'thiss_js',
    description  => 'SA identity selector software',
    compose_dir  => '/opt/static/compose',
    content => template('thiss/static/thiss-js_beta.yml.erb'),
  }

  sunet::nagios::nrpe_command {"check_sa_version":
    command_line => "/usr/lib/nagios/plugins/check_http -H localhost -u http://localhost/manifest.json -s ${ds_version_beta}"
  }
}
