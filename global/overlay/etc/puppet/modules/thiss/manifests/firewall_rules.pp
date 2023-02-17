class thiss::firewall_rules($location=undef){

  $md_ip = hiera_array("md_${location}",[])
  $haproxy_ip = hiera_array("haproxy_${location}",[])
  $haproxy_static_ip = hiera_array("haproxy_static_${location}",[])
  $nagios_ip_v4 = hiera_array('nagios_ip_v4',[])

  #metadata aggregator expose port 443 to mdq
  if $::fqdn =~ /^meta\.\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_https_aggregator':
      from =>  $md_ip + $nagios_ip_v4,
      port => '443',
    }
  }
  #mdq exposes 80 to haproxy
  if $::fqdn =~ /^md-[0-9]+\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_http_mdq':
      from => $haproxy_ip + $nagios_ip_v4,
      port => '80',
    }
  }
  #haproxy exposes 443 to Internet
  if $::fqdn =~ /^md\.\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { "allow_https_haproxy":
      from => 'any',
      port => '443',
    }
  }
  #static exposes 80 to haproxy
  if $::fqdn =~ /^static-[0-9]+\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_http_static':
      from => $haproxy_static_ip + $nagios_ip_v4,
      port => '80',
    }
  }
  #haproxy exposes 443 to Internet
  if $::fqdn =~ /^static\.\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { "allow_https_haproxy_static":
      from => 'any',
      port => '443',
    }
  }
  #static exposes 8404 to nagios
  if $::fqdn =~ /^static\.\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_haproxy_stat':
      from => $nagios_ip_v4,
      port => '8404',
    }
  }
}
