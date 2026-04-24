class thiss::haproxy_md($location=undef,$image_tag=undef){

  ensure_resource(sunet::misc::system_user, 'haproxy', {group => 'haproxy' })

  $infra_cert = $::tls_certificates[$facts['networking']['fqdn']]['infra_bundle']
  $infra_key = $::tls_certificates[$facts['networking']['fqdn']]['infra_key']
  ensure_resource(sunet::misc::certbundle, "${facts['networking']['fqdn']}_haproxy", {
    group  => 'haproxy',
    bundle => ["cert=${infra_cert}",
               "key=${infra_key}",
               "out=/etc/ssl/private/${facts['networking']['fqdn']}_haproxy.crt",
               ],
  })

  ensure_resource('file','/opt/haproxy', { ensure => directory } )
  ensure_resource('file','/opt/haproxy/compose', { ensure => directory } )
  $servers = hiera_hash("md_${location}")

  file { '/opt/haproxy/haproxy.cfg':
    content      => template('thiss/haproxy/haproxy_md.cfg.erb'),
    owner        => root,
    group        => 'haproxy',
    mode         => '0640'
  }

  sunet::nftables::docker_expose { 'haproxy' :
    allow_clients => 'any',
    port          => '443',
    iif           => "${interface_default}",
  }

  if $facts['networking']['fqdn'] = 'md-lb.thiss.io' {
    $nagios_ip_v4 = hiera_array('nagios_ip_v4',[])
    $sunet_vpn = hiera_array('sunet_vpn',[])
    sunet::nftables::docker_expose { 'haproxy-stats' :
      allow_clients => $$nagios_ip_v4 + $sunet_vpn,
      port          => '8404',
      iif           => "${interface_default}",
    }
  }

  sunet::docker_compose {'haproxy_docker_compose':
    service_name => 'haproxy_seamlessaccess',
    description  => 'HAProxy Load Blanacer for thiss-mdq',
    compose_dir  => '/opt/haproxy/compose',
    content => template('thiss/haproxy/haproxy_md.yml.erb'),
  }
}