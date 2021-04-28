class thiss::firewall_rules($location=undef){

  $md_ip = hiera_array("md_${location}",[])
  $haproxy_ip = hiera_array("haproxy_${location}",[])
  $nagios_ip_v4 = hiera_array('nagios_ip_v4',[])

  #metadata aggregator expose port 443 to mdq
  if $::fqdn =~ /^meta\.\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_http_aggregator':
      from =>  $md_ip + $nagios_ip_v4,
      port => '443',
    }
  }
  #mdq exposes 80 to haproxy
  if $::fqdn =~ /^md-[0-9]+\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_https_mdq':
      from => $haproxy_ip,
      port => '80',
    }
  }
  #haproxy exposes 443 to Internet
  if $::fqdn =~ /^md\.\S+\.seamlessaccess\.org$/ {
    ufw::allow { "allow_https_haproxy":
      ip   => 'any',
      port => '443',
    }
  }
}
