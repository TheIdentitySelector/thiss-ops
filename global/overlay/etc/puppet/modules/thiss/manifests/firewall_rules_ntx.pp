class thiss::firewall_rules_ntx{

  $md_ntx = hiera_array('md_ntx',[])
  $haproxy_ntx = hiera_array('haproxy_ntx',[])

  #aggregator expose port 80 to md
  if $::fqdn =~ /^a-[0-9]+\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_http_aggregator':
      from =>  $md_ntx,
      port => '80',
    }
  }
  #mdq exposes 443 to haproxy
  if $::fqdn =~ /^md-[0-9]+\S+\.seamlessaccess\.org$/ {
    sunet::misc::ufw_allow { 'allow_https_mdq':
      from => $haproxy_ntx,
      port => '443',
    }
  }
  #haproxy exposes 443 to Internet
  if $::fqdn == 'md.ntx.sunet.eu.seamlessaccess.org' {
    ufw::allow { "allow_https_haproxy":
      ip   => 'any',
      port => '443',
    }
  }

}