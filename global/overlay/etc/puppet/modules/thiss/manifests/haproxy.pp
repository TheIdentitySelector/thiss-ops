class thiss::haproxy($location=undef){

  ensure_resource(sunet::misc::system_user, 'haproxy', {group => 'haproxy' })

  $infra_cert = $::tls_certificates[$::fqdn]['infra_cert']
  $infra_key = $::tls_certificates[$::fqdn]['infra_key']
  ensure_resource(sunet::misc::certbundle, "${::fqdn}_haproxy", {
    group  => 'haproxy',
    bundle => ["cert=${infra_cert}",
               "key=${infra_key}",
               "out=private/${::fqdn}_haproxy.crt",
               ],
  })

    ensure_resource('file','/opt/haproxy', { ensure => directory } )
    ensure_resource('file','/opt/haproxy/compose', { ensure => directory } )
    $servers = hiera_array("md_${location}",[])

    file { '/opt/haproxy/haproxy.cfg':
      content      => template('thiss/haproxy/haproxy.cfg.erb'),
      owner        => root,
      group        => 'haproxy',
      mode         => '0640'
    }

  sunet::docker_compose {'haproxy_docker_compose':
    service_name => 'haproxy_seamlessaccess',
    description  => 'HAProxy Load Blanacer for mdq',
    compose_dir  => '/opt/haproxy/compose',
    content => template('thiss/haproxy/haproxy_seamlessaccess.yml.erb'),
  }
}
