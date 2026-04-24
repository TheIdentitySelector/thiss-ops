# This class is used to define custom checks for hosts or groups of hosts
class thiss::naemon_monitor_config {

  $localhost = $facts['networking']['fqdn']

  class {'nagioscfg::slack': domain => 'seamlessaccess.slack.com', token => safe_hiera('slack_token','') }
  nagioscfg::slack::channel {'nagios': } ->
  nagioscfg::contact {'slack-alerts':
    host_notification_options     => 'd,u,r,f',
    service_notification_options  => 'w,u,c,r,f',
    host_notification_commands    => ['notify-host-to-slack-nagios'],
    service_notification_commands => ['notify-service-to-slack-nagios'],
    contact_groups                => ['alerts']
  }

  nagioscfg::service {'metadata_aggregate_age':
    hostgroup_name => ['thiss::pyff_prod','thiss::pyff_staging','thiss::pyff_beta'],
    check_command  => 'check_nrpe!check_fileage_metadata_aggregate',
    description    => 'metadata aggregate age',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'metadata_sp_aggregate_age':
    hostgroup_name => ['thiss::pyff_prod','thiss::pyff_staging','thiss::pyff_beta'],
    check_command  => 'check_nrpe!check_fileage_metadata_sp_aggregate',
    description    => 'SP trust metadata aggregate age',
    contact_groups => ['alerts']
  }
  $md_files = ['eduGAIN.xml', 'incommon.xml', 'openathens.xml', 'swamid-registered.xml']
  $md_files.each |$md_file|{
    nagioscfg::service {"metadata_age_${md_file}":
      hostgroup_name => ['thiss::pyff_prod','thiss::pyff_staging','thiss::pyff_beta'],
      check_command  => "check_nrpe!check_fileage_${md_file}",
      description    => "file age of ${md_file}",
      contact_groups => ['alerts']
    }
   }
  nagioscfg::service {'check_needrestart':
    hostgroup_name => ['common'],
    check_command  => 'check_nrpe!check_needrestart',
    description    => 'Processes need restart',
    contact_groups => ['alerts']
  }
  nagioscfg::command {'check_ssl_cert_3':
    command_line   => "/usr/lib/nagios/plugins/check_ssl_cert -A -H '\$HOSTNAME\$' -c '\$ARG2\$' -w '\$ARG1\$' -p '\$ARG3\$'"
  }
  nagioscfg::command {'check_ssl_cert_3_without_sct':
    command_line   => "/usr/lib/nagios/plugins/check_ssl_cert -A -H '\$HOSTNAME\$' --ignore-sct -c '\$ARG2\$' -w '\$ARG1\$' -p '\$ARG3\$'"
  }
  nagioscfg::command {'check_website':
    command_line   => "/usr/lib/nagios/plugins/check_http -H '\$HOSTNAME\$' -S -u '\$ARG1\$' --sni"
  }
  nagioscfg::command {'check_website_string':
    command_line   => "/usr/lib/nagios/plugins/check_http -H '\$HOSTNAME\$' -S -u '\$ARG1\$'  -s '\$ARG2\$'"
  }
  nagioscfg::command {'check_website_http':
    command_line   => "/usr/lib/nagios/plugins/check_http -H '\$HOSTNAME\$' -u '\$ARG1\$' -s '\$ARG2\$'"
  }
  nagioscfg::command {'check_metadata_age':
    command_line   => "/usr/lib/nagios/plugins/check_md_sa.sh '\$ARG1\$'"
  }
  nagioscfg::command {'check_metadata_sp_age':
    command_line   => "/usr/lib/nagios/plugins/check_md_sp_sa.sh '\$ARG1\$'"
  }
  nagioscfg::command {'check_haproxy_backend':
    command_line   => "/usr/lib/nagios/plugins/check_haproxy.rb -u '\$ARG1\$'"
  }
  nagioscfg::command {'check_service_cluster':
    command_line   => "/usr/lib/nagios/plugins/check_cluster --service -l '\$ARG1\$' -w '\$ARG2\$' -c '\$ARG3\$' -d '\$ARG4\$'"
  }
  $public_hosts = ['use.thiss.io','md.thiss.io','md.seamlessaccess.org','service.seamlessaccess.org','seamlessaccess.org','md-staging.thiss.io']
  nagioscfg::host {$public_hosts: sort_alphabetically => true }
  $md_haproxy_hosts = ['md-lb.thiss.io', 'md.ntx.sunet.eu.seamlessaccess.org', 'md.se-east.sunet.eu.seamlessaccess.org', 'md.aws1.geant.eu.seamlessaccess.org', 'md.aws2.geant.eu.seamlessaccess.org']
  $meta_hosts = ['meta.aws1.geant.eu.seamlessaccess.org', 'meta.aws2.geant.eu.seamlessaccess.org', 'meta.se-east.sunet.eu.seamlessaccess.org', 'meta.ntx.sunet.eu.seamlessaccess.org', 'a-1.thiss.io', 'a-staging-2.thiss.io']
  $static_haproxy_hosts = ['static.aws2.thiss.io', 'static.thiss.io', 'static.ntx.sunet.eu.seamlessaccess.org', 'static.se-east.sunet.eu.seamlessaccess.org', 'static.aws1.geant.eu.seamlessaccess.org', 'static.aws2.geant.eu.seamlessaccess.org']
  $urls = concat ($public_hosts, $md_haproxy_hosts, $static_haproxy_hosts)
  $urls.each |$url|{
    nagioscfg::service {"check_${url}":
      host_name      => ["${url}"],
      check_command  => "check_website!https://${url}",
      description    => 'check web',
      contact_groups => ['alerts'],
    }
  }
  $static_haproxy_hosts.each |$host|{
    nagioscfg::service {"check_haproxy_backend_${host}":
      host_name      => [$localhost],
      check_command  => "check_haproxy_backend!http://${host}:8404/stats",
      description    => "check HAproxy backends for ${host}",
      contact_groups => ['alerts'],
    }
  }
  $md_haproxy_hosts.each |$host|{
    nagioscfg::service {"check_haproxy_backend_${host}":
      host_name      => [$localhost],
      check_command  => "check_haproxy_backend!http://${host}:8404/stats",
      description    => "check HAproxy backends for ${host}",
      contact_groups => ['alerts'],
    }
    nagioscfg::service {"check_website_status${host}":

      check_command  => "check_website_string!https://${host}/status!OK",
      description    => "check status for https://${host}/status",
      contact_groups => ['alerts'],
    }
  }
  nagioscfg::service {'check_public_ssl_cert':
    host_name      => $public_hosts,
    check_command  => 'check_ssl_cert_3!30!14!443',
    description    => 'check https certificate validity on port 443',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_infra_ssl_cert':
    host_name      => $md_haproxy_hosts + $meta_hosts + $static_haproxy_hosts,
    check_command  => 'check_ssl_cert_3_without_sct!30!14!443',
    description    => 'check https infra certificate validity on port 443',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'static_check_web_clustercheck':
    host_name      => [$localhost],
    check_command  => 'check_service_cluster!"check web"!0!1!$SERVICESTATEID:static.aws1.geant.eu.seamlessaccess.org:check web$,$SERVICESTATEID:static.aws2.geant.eu.seamlessaccess.org:check web$,$SERVICESTATEID:static.ntx.sunet.eu.seamlessaccess.org:check web$,$SERVICESTATEID:static.se-east.sunet.eu.seamlessaccess.org:check web$',
    description    => 'check web - static clustercheck',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'md_check_web_clustercheck':
    host_name      => [$localhost],
    check_command  => 'check_service_cluster!"check web"!0!1!$SERVICESTATEID:md.aws1.geant.eu.seamlessaccess.org:check web$,$SERVICESTATEID:md.aws2.geant.eu.seamlessaccess.org:check web$,$SERVICESTATEID:md.ntx.sunet.eu.seamlessaccess.org:check web$,$SERVICESTATEID:md.se-east.sunet.eu.seamlessaccess.org:check web$',
    description    => 'check web - md clustercheck',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'md_check_metadata_clustercheck':
    host_name      => [$localhost],
    check_command  => 'check_service_cluster!"check metadata"!0!1!$SERVICESTATEID:md.aws1.geant.eu.seamlessaccess.org:check metadata for md.aws1.geant.eu.seamlessaccess.org$,$SERVICESTATEID:md.aws2.geant.eu.seamlessaccess.org:check metadata for md.aws2.geant.eu.seamlessaccess.org$,$SERVICESTATEID:md.ntx.sunet.eu.seamlessaccess.org:check metadata for md.ntx.sunet.eu.seamlessaccess.org$,$SERVICESTATEID:md.se-east.sunet.eu.seamlessaccess.org:check metadata for md.se-east.sunet.eu.seamlessaccess.org$',
    description    => 'check metadata - md clustercheck',
    contact_groups => ['alerts']
  }
  $md_urls = concat ([ 'md.thiss.io', 'md.seamlessaccess.org', 'md-staging.thiss.io'] , $md_haproxy_hosts)
  $md_urls.each |$url|{
    nagioscfg::service {"check_metadata_age_${url}":
      host_name      => ["${url}"],
      check_command  => "check_metadata_age!https://${url}",
      description    => "check metadata for ${url}",
      contact_groups => ['alerts'],
    }
    nagioscfg::service {"check_metadata_sp_age_${url}":
      host_name      => ["${url}"],
      check_command  => "check_metadata_sp_age!https://${url}",
      description    => "check SP trust metadata for ${url}",
      contact_groups => ['alerts'],
    }
  }
  $md_hosts = ['md-1.ntx.sunet.eu.seamlessaccess.org', 'md-1.se-east.sunet.eu.seamlessaccess.org', 'md-1.aws1.geant.eu.seamlessaccess.org', 'md-1.aws2.geant.eu.seamlessaccess.org','md-2.ntx.sunet.eu.seamlessaccess.org', 'md-2.se-east.sunet.eu.seamlessaccess.org', 'md-2.aws1.geant.eu.seamlessaccess.org', 'md-2.aws2.geant.eu.seamlessaccess.org', 'md-1.thiss.io', 'md-2.thiss.io']
  $md_hosts.each |$host|{
    nagioscfg::service {"check_metadata_age_${host}":
      host_name      => ["${host}"],
      check_command  => "check_metadata_age!http://${host}",
      description    => "check metadata for ${host}",
      contact_groups => ['alerts'],
    }
    nagioscfg::service {"check_metadata_sp_age_${host}":
      host_name      => ["${host}"],
      check_command  => "check_metadata_sp_age!http://${host}",
      description    => "check SP trust metadata for ${host}",
      contact_groups => ['alerts'],
    }
    nagioscfg::service {"check_website_status${host}":
      host_name      => ["${host}"],
      check_command  => "check_website_http!http://${host}/status!OK",
      description    => "check web for ${host}",
      contact_groups => ['alerts'],
    }
  }
  $static_hosts = ['static-1.aws2.thiss.io', 'static-2.aws2.thiss.io', 'static-1.thiss.io', 'static-1.ntx.sunet.eu.seamlessaccess.org', 'static-1.se-east.sunet.eu.seamlessaccess.org', 'static-1.aws1.geant.eu.seamlessaccess.org', 'static-1.aws2.geant.eu.seamlessaccess.org', 'static-2.thiss.io', 'static-2.ntx.sunet.eu.seamlessaccess.org', 'static-2.se-east.sunet.eu.seamlessaccess.org', 'static-2.aws1.geant.eu.seamlessaccess.org', 'static-2.aws2.geant.eu.seamlessaccess.org']
  $static_hosts.each |$host|{
    nagioscfg::service {"check_${host}":
      host_name      => ["${host}"],
      check_command  => "check_website_http!http://${host}/manifest.json!version",
      description    => 'check web',
      contact_groups => ['alerts'],
    }
  }
  nagioscfg::service {"check_sa_version_beta":
    hostgroup_name => ['thiss::static_beta'],
    check_command  => "check_nrpe!check_sa_version",
    description    => 'check thiss-js version in Beta',
    contact_groups => ['alerts'],
  }
  nagioscfg::service {"check_sa_version_prod":
    hostgroup_name => ['thiss::static_prod'],
    check_command  => "check_nrpe!check_sa_version",
    description    => 'check thiss-js version in Beta',
    contact_groups => ['alerts'],
  }
}
