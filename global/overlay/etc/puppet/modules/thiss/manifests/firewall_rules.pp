class thiss::firewall_rules($location=undef){

  #$md_servers = {md_servers => {backends => {'md-1.ntx.sunet.eu.seamlessaccess.org' => {ip => 123}, 'md-2.ntx.sunet.eu.seamlessaccess.org' => {ip => 456}}}}
  $md_servers = hiera_hash ("md_${location}")
  $haproxy_md_ip = hiera_array("haproxy_md_${location}",[])
  $haproxy_static_ip = hiera_array("haproxy_static_${location}",[])
  $nagios_ip_v4 = hiera_array('nagios_ip_v4',[])

  #metadata aggregator expose port 443 to mdq
  $facts['networking']['fqdn'] =~ /^meta\.\S+\.seamlessaccess\.org$/ {
    $md_servers.each |$md_servers_key, $md_servers_value_hash|{
      $md_servers_value_hash['backends'].each |$backend_key, $backend_value_hash|{
        sunet::misc::ufw_allow { "allow_https_${backend_value_hash['ip']}":
          from => $backend_value_hash['ip'],
          port => '443',
        }
      }
    }
  }
  #metadata aggregator expose port 443 to nagios
  if $facts['networking']['fqdn'] =~ /^meta\.\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_https_nagios':
      from => $nagios_ip_v4,
      port => '443',
    }
  }
  #mdq exposes 80 to haproxy and nagios
  if $facts['networking']['fqdn'] =~ /^md-[0-9]+\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_http_mdq':
      from => $haproxy_md_ip + $nagios_ip_v4,
      port => '80',
    }
  }
  #haproxy exposes 443 to Internet
  if $facts['networking']['fqdn'] =~ /^md\.\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { "allow_https_haproxy_md":
      from => 'any',
      port => '443',
    }
  }
  #haproxy exposes 8404 to nagios
  if $facts['networking']['fqdn'] =~ /^md\.\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_haproxy_md_stats':
      from => $nagios_ip_v4,
      port => '8404',
    }
  }
  #static exposes 80 to haproxy and nagios
  if $facts['networking']['fqdn'] =~ /^static-[0-9]+\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_http_static':
      from => $haproxy_static_ip + $nagios_ip_v4,
      port => '80',
    }
  }
  #haproxy exposes 443 to Internet
  if $facts['networking']['fqdn'] =~ /^static\.\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { "allow_https_haproxy_static":
      from => 'any',
      port => '443',
    }
  }
  #static exposes 8404 to nagios
  if $facts['networking']['fqdn'] =~ /^static\.\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_haproxy_static_stats':
      from => $nagios_ip_v4,
      port => '8404',
    }
  }
}
