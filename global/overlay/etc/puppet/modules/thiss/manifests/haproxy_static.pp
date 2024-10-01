class thiss::haproxy_static($location=undef,$image_tag=undef){

  ensure_resource(sunet::misc::system_user, 'haproxy', {group => 'haproxy' })

  $infra_cert = $::tls_certificates[$::fqdn]['infra_bundle']
  $infra_key = $::tls_certificates[$::fqdn]['infra_key']
  ensure_resource(sunet::misc::certbundle, "${::fqdn}_haproxy", {
    group  => 'haproxy',
    bundle => ["cert=${infra_cert}",
               "key=${infra_key}",
               "out=/etc/ssl/private/${::fqdn}_haproxy.crt",
               ],
  })

    ensure_resource('file','/opt/haproxy', { ensure => directory } )
    ensure_resource('file','/opt/haproxy/compose', { ensure => directory } )
    $servers = hiera_hash("static_${location}")

    file { '/opt/haproxy/haproxy.cfg':
      content      => template('thiss/haproxy/haproxy_static.cfg.erb'),
      owner        => root,
      group        => 'haproxy',
      mode         => '0640'
    }

  if $::sunet_nftables_opt_in == 'yes' and ( $::operatingsystem == 'Ubuntu' and versioncmp($::operatingsystemrelease, '20.04') == 0 ){
    sunet::nftables::docker_expose { 'haproxy_older_ubuntu' :
      allow_clients => 'any',
      port          => '443',
    }
    sunet::nftables::docker_expose { 'haproxy-stats_older_ubuntu' :
      allow_clients => ['130.242.121.23/32', '192.36.171.83/32'],
      port          => '8404',
    }
}
if ( $::operatingsystem == 'Ubuntu' and versioncmp($::operatingsystemrelease, '22.04') >= 0 ) {
    sunet::nftables::docker_expose { 'haproxy' :
      allow_clients => 'any',
      port          => '443',
      iif           => "${interface_default}",
    }
    sunet::nftables::docker_expose { 'haproxy-stats' :
      allow_clients => ['130.242.121.23/32', '192.36.171.83/32'],
      port          => '8404',
      iif           => "${interface_default}",
    }

}

  sunet::docker_compose {'haproxy_docker_compose':
    service_name => 'haproxy_seamlessaccess',
    description  => 'HAProxy Load Blanacer for thiss-js',
    compose_dir  => '/opt/haproxy/compose',
    content => template('thiss/haproxy/haproxy_seamlessaccess_static.yml.erb'),
  }
}