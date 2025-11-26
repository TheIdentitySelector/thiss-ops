# This manifest is managed using cosmos

Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
}

include sunet

class mailclient ($domain) {
   sunet::preseed_package {"postfix": ensure => present, options => {domain => $domain}}
}

class autoupdate {
   class { 'sunet::updater': cron => true, cosmos_automatic_reboot => true }
}

class infra_ca_rp {
   sunet::ici_ca::rp { 'infra': }
}

# you need a default node, all nodes need ssh + ufw
node default {
}

class common {
  include sunet::tools
  include sunet::motd
  include sunet::ntp

  if $::sunet_nftables_opt_in != 'yes' and ! ( $::operatingsystem == 'Ubuntu' and versioncmp($::operatingsystemrelease, '22.04') >= 0 ) {
    warning('Enabling UFW')
    include ufw
  } else {
    warning('Enabling nftables')
    ensure_resource ('class','sunet::nftables::init', { })
  }

  # Only import appaprmor for ubuntu22 and older
  if ($facts['os']['name'] == 'Ubuntu' and versioncmp($facts['os']['release']['full'], '22.04') <= 0 ){
   include apparmor
  }

  include apt
  package { 'needrestart': ensure => installed}
  }

# remove unencrypted git protocol
  exec { 'run_secure_git':
    cwd     => '/var/cache/cosmos/repo',
    command => '/usr/bin/git remote set-url origin https://github.com/TheIdentitySelector/thiss-ops git://github.com/TheIdentitySelector/thiss-ops.git',
    onlyif  => '/usr/bin/git remote get-url origin | grep -qi git://github.com/TheIdentitySelector/thiss-ops.git',
  }

class dhcp6_client {
  sunet::misc::ufw_allow { "allow-dhcp6-546":
      from    => 'any',
      port  => '546',
      proto => 'udp',
  }
  sunet::misc::ufw_allow { "allow-dhcp6-547":
      from    => 'any',
      port  => '547',
      proto => 'udp'
  }
}

class md_aggregator {}

class entropyclient {
   # Entropy is not needed on modern kernels
   if ($facts['os']['name'] == 'Ubuntu' and versioncmp($facts['os']['release']['full'], '22.04') <= 0 ){
      include sunet::simple_entropy
      sunet::ucrandom {'random.nordu.net': ensure => absent }
      sunet::nagios::nrpe_check_process { 'haveged': }
   }
}

class openstack_dockerhost {
   class { 'sunet::dockerhost':
      docker_version            => '17.12.0~ce-0~ubuntu',
      docker_package_name       => 'docker-ce',
      storage_driver            => "aufs",
      run_docker_cleanup        => true,
      manage_dockerhost_unbound => true,
      docker_network            => true
   }
}

class update_ca_certificates {
   exec { 'do_update_ca_certificates': command => '/usr/sbin/update-ca-certificates' }
}

class sunet_iaas_cloud {
   sunet::cloud_init::config { 'disable_datasources':
      config => { datasource_list => [ 'None' ] }
   }
   sunet::cloud_init::config { 'keep_root_enabled':
      config => { disable_root => 'false' }
   }
}

class https {
   sunet::misc::ufw_allow { "allow-https":
      from => 'any',
      port => '443'
   }
}

class http {
   sunet::misc::ufw_allow { "allow-http":
      from => 'any',
      port => '80'
   }
}


class servicemonitor {
   $nagios_ip_v4 = join(hiera('nagios_ip_v4')," ");
   sunet::misc::ufw_allow { "allow-servicemonitor-from-nagios":
      ip   => $nagios_ip_v4,
      port => '444',
      ensure => absent
   }
}

class github_client_credential {
   sunet::ssh_host_credential { "github":
      hostname    => "github.com",
      id          => "github",
      manage_user => false
   }
}

class ops {
  # SSH config, create SSH authorized keys from Hiera
  $ssh_authorized_keys = hiera_hash('ssh_authorized_keys', undef)
  if $ssh_authorized_keys =~ Hash {
    create_resources('ssh_authorized_key', $ssh_authorized_keys)
  }

  ssh_authorized_key {'leifj+neo':
    ensure  => present,
    name    => 'leifj+neo@mnt.se',
    key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDVvB4gdJ6EWRmx8xUSxrhoUNnWxEf8ZwAqhzC1+7XBY/hSd/cbEotLB9gxgqt0CLW56VU4FPLTw8snD8tgsyZN6KH1Da7UXno8oMk8tJdwLQM0Ggx3aWuztItkDfBc3Lfvq5T07YfphqJO7rcSGbS4QQdflXuOM9JLi6NStVao0ia4aE6Tj68pVVb3++XYvqvbU6NtEICvkTxEY93YpnRSfeAi64hsbaqSTN4kpeltzoSD1Rikz2aQFtFXE03ZC48HtGGhdMFA/Ade6KWBDaXxHGARVQ9/UccfhaR2XSjVxSZ8FBNOzNsH4k9cQIb2ndkEOXZXnjF5ZjdI4ZU0F+t7',
    type    => 'ssh-rsa',
    user    => 'root'
  }

  # OS hardening
  if $facts['networking']['fqdn'] =~ /kvm/ {
    class {'bastion':
      fstab_fix_shm        => false,
      sysctl_net_hardening => false,
    }
  } elsif $facts['networking']['fqdn']  =~ /random/ {  # pollen requires exec on /tmp
    class {'bastion':
      fixperms_enable      => false,
      fixperms_paranoia    => false,
    }
  } else {
    class {'bastion':
      fstab_fix_shm     => false,
      fixperms_paranoia => true,
    }
  }
}

class nrpe {
  require apt
  class {'sunet::nagios': }
  package {'nagios-plugins-contrib': ensure => latest}

  if ($facts['os']['name']  == 'Ubuntu' and versioncmp($facts['os']['release']['full'], '22.04') >= 0 ){
    $mem_w = '90'
    $mem_c = '95'
  } else {
    $mem_w = '10'
    $mem_c = '5'
  }
  sunet::nagios::nrpe_command {'check_memory':
    command_line => "/usr/lib/nagios/plugins/check_memory -w ${mem_w}% -c ${mem_c}%"
  }
  sunet::nagios::nrpe_command {'check_mem':
    command_line => '/usr/lib/nagios/plugins/check_memory -w 10% -c 5%'
  }
  sunet::nagios::nrpe_command {'check_boot_15_5':
    command_line => '/usr/lib/nagios/plugins/check_disk -w 15% -c 5% -p /boot'
  }
  sunet::nagios::nrpe_command {'check_entropy':
    command_line => '/usr/lib/nagios/plugins/check_entropy -w 200'
  }
  if ($facts['os']['name'] == 'Ubuntu' and versioncmp($facts['os']['release']['full'], '22.04') > 0 ){
    sunet::nagios::nrpe_command {'check_ntp_time':
      command_line => '/usr/lib/nagios/plugins/check_ntp_time -H ntp.se'
    }
  } else {
      sunet::nagios::nrpe_command {'check_ntp_time':
        command_line => '/usr/lib/nagios/plugins/check_ntp_time -H localhost'
      }
  }
  sunet::nagios::nrpe_command {'check_scriptherder':
    command_line => '/usr/local/bin/scriptherder --mode check'
  }
  sunet::nagios::nrpe_command {'check_apt':
    command_line => '/usr/lib/nagios/plugins/check_apt'
  }
  sunet::sudoer {'nagios_run_needrestart_command':
    user_name    => 'nagios',
    collection   => 'nagios',
    command_line => "/usr/sbin/needrestart -p -l"
  }
  sunet::nagios::nrpe_command {'check_needrestart':
    command_line => "sudo /usr/sbin/needrestart -p -l"
  }
}

class nagios_monitor {
  $nrpe_clients = hiera_array('nrpe_clients',[]);
  $allowed_hosts = join($nrpe_clients," ");
  $web_admin_pw   = safe_hiera('nagios_nagiosadmin_password');
  $web_admin_user = 'nagiosadmin';
   
  class { 'nagioscfg':
    hostgroups      => $::roles,
    config          => 'seamless',
    manage_package  => false,
    cfgdir          => '/etc/nagios4/conf.d',
    service         => 'nagios4',
    host_template   => 'monitor-host',
    single_ip       => true,
  }

  ensure_resource('package','nagios4', { ensure => present })
  ensure_resource('package','nagios-nrpe-plugin', { ensure => present })

  #web interface configs specifically for monitor.seamlessaccess.org
  class { 'http': }
  sunet::misc::ufw_allow { 'allow_sunet_vpn': from => '130.242.121.23', port => '443', }
  class { 'sunet::dehydrated::client':
    domain     => 'monitor.seamlessaccess.org',
    ssl_links  => true,
    check_cert => true,
  }
  service { 'apache2':
    ensure  => running,
    enable  => true,
  }
  file { '/etc/apache2/sites-available/000-default.conf':
    ensure  => file,
    mode    => '0644',
    content => template('thiss/monitor/000-default.conf.erb'),
    notify => Service['apache2'],
  }
  file { '/etc/apache2/sites-available/monitor-ssl.conf':
    ensure  => file,
    mode    => '0644',
    content => template('thiss/monitor/monitor-ssl.conf.erb'),
    notify  => Service['apache2'],
  }
  exec { 'a2ensite monitor-ssl.conf':
    creates     => '/etc/apache2/sites-enabled/monitor-ssl.conf',
    notify      => Service['apache2'],
  }
  exec { 'a2enmod proxy && a2enmod proxy_http && a2enmod headers':
    subscribe   => File['/etc/apache2/sites-available/000-default.conf'],
    refreshonly => true,
    notify      => Service['apache2'],
  }
  exec { 'a2enmod ssl':
    subscribe   => File['/etc/apache2/sites-available/monitor-ssl.conf'],
    refreshonly => true,
    notify      => Service['apache2'],
  }
  exec { 'enable auth_digest':
    command => 'a2enmod auth_digest',
    creates => '/etc/apache2/mods-enabled/auth_digest.load',
    notify  => Service['apache2'],
  }
  exec { 'enable authz_groupfile':
    command => 'a2enmod authz_groupfile',
    creates => '/etc/apache2/mods-enabled/authz_groupfile.load',
    notify  => Service['apache2'],
  }

  #definition for check_nrpe_1arg
  file { '/etc/nagios-plugins/config/check_nrpe.cfg':
    ensure  => file,
    mode    => '0644',
    content => template('thiss/monitor/check_nrpe.cfg.erb'),
  }

  class {'nagioscfg::slack': domain => 'seamlessaccess.slack.com', token => safe_hiera('slack_token','') } ->
  class {'nagioscfg::passive': enable_notifications => '1', obsess_over_services => '0', obsess_over_hosts => '0', nagios_config_file   => '/etc/nagios4/nagios.cfg'}

  sunet::misc::htpasswd_user { $web_admin_user :
    filename => "/etc/nagios4/htpasswd.users",
    password => $web_admin_pw,
    group    => 'www-data',
  }

  file { '/etc/apache2/conf-enabled/nagios4-cgi.conf':
    ensure  => file,
    mode    => '0644',
    content => template('thiss/monitor/nagios4-cgi.conf.erb'),
  }

  #definition for standard hostgroups
  file { '/etc/nagios4/conf.d/hostgroups_nagios4.cfg':
    ensure  => file,
    mode    => '0644',
    content => template('thiss/monitor/hostgroups_nagios4.cfg.erb'),
  }
  file { '/etc/nagios4/conf.d/monitor-host_nagios4.cfg':
    ensure  => file,
    mode    => '0644',
    content => template('thiss/monitor/monitor-host_nagios4.cfg.erb'),
  }
  file { '/etc/nagios4/conf.d/monitor-service_nagios4.cfg':
    ensure  => file,
    mode    => '0644',
    content => template('thiss/monitor/monitor-service_nagios4.cfg.erb'),
  }

  file {'/root/MONITOR_WEB_PASSWORD':
    content => sprintf("%s\n%s\n", $web_admin_user, $web_admin_pw),
    group   => 'root',
    mode    => '0600',
  }
  nagioscfg::slack::channel {'nagios': } ->
  nagioscfg::contactgroup {'alerts': } ->
  nagioscfg::contact {'slack-alerts':
    host_notification_options     => 'd,u,r,f',
    service_notification_options  => 'w,u,c,r,f',
    host_notification_commands    => ['notify-host-to-slack-nagios'],
    service_notification_commands => ['notify-service-to-slack-nagios'],
    contact_groups                => ['alerts']
  }
  nagioscfg::service {'service_ping':
    hostgroup_name => ['all'],
    use            => 'monitor-service',
    description    => 'PING',
    check_command  => 'check_ping!400.0,1%!500.0,2%',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_load':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_load',
    description    => 'System Load',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_users':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_users',
    description    => 'Active Users',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_zombie_procs':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_zombie_procs',
    description    => 'Zombie Processes',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_total_procs':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_total_procs_lax',
    description    => 'Total Processes',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_root':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_root',
    description    => 'Root Disk',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_boot':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_boot_15_5',
    description    => 'Boot Disk',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_var':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_var',
    description    => 'Var Disk',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_uptime':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_uptime',
    description    => 'Uptime',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_reboot':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_reboot',
    description    => 'Reboot Needed',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_memory':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_memory',
    description    => 'System Memory',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_entropy':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_entropy',
    description    => 'System Entropy',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_ntp_time':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_ntp_time',
    description    => 'System NTP Time',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_process_haveged':
    hostgroup_name => ['entropyclient'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_process_haveged',
    description    => 'haveged running',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_scriptherder':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_scriptherder',
    description    => 'Scriptherder Status',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'metadata_aggregate_age':
    hostgroup_name => ['md_aggregator'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_fileage_metadata_aggregate',
    description    => 'metadata aggregate age',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'metadata_sp_aggregate_age':
    hostgroup_name => ['md_aggregator'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_fileage_metadata_sp_aggregate',
    description    => 'SP trust metadata aggregate age',
    contact_groups => ['alerts']
  }
  $md_files = ['eduGAIN.xml', 'incommon.xml', 'openathens.xml', 'swamid-registered.xml']
  $md_files.each |$md_file|{
    nagioscfg::service {"metadata_age_${md_file}":
      hostgroup_name => ['md_aggregator'],
      use            => 'monitor-service',
      check_command  => "check_nrpe_1arg!check_fileage_${md_file}",
      description    => "file age of ${md_file}",
      contact_groups => ['alerts']
    }
   }
  nagioscfg::service {'check_needrestart':
    hostgroup_name => ['nrpe'],
    use            => 'monitor-service',
    check_command  => 'check_nrpe_1arg!check_needrestart',
    description    => 'Processes need restart',
    contact_groups => ['alerts']
  }
  nagioscfg::command {'check_ssl_cert_3':
    command_line   => "/usr/lib/nagios/plugins/check_ssl_cert -A -H '\$HOSTNAME\$' -c '\$ARG2\$' -w '\$ARG1\$' -p '\$ARG3\$'"
  }
  nagioscfg::command {'check_ssl_cert_3_without_ocsp':
    command_line   => "/usr/lib/nagios/plugins/check_ssl_cert -A -H '\$HOSTNAME\$' --ignore-ocsp -c '\$ARG2\$' -w '\$ARG1\$' -p '\$ARG3\$'"
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
      use            => 'monitor-service',
      check_command  => "check_website!https://${url}",
      description    => 'check web',
      contact_groups => ['alerts'],
    }
  }
  $static_haproxy_hosts.each |$host|{
    nagioscfg::service {"check_haproxy_backend_${host}":
      host_name      => [localhost],
      use            => 'monitor-service',
      check_command  => "check_haproxy_backend!http://${host}:8404/stats",
      description    => "check HAproxy backends for ${host}",
      contact_groups => ['alerts'],
    }
  }
  $md_haproxy_hosts.each |$host|{
    nagioscfg::service {"check_haproxy_backend_${host}":
      host_name      => [localhost],
      use            => 'monitor-service',
      check_command  => "check_haproxy_backend!http://${host}:8404/stats",
      description    => "check HAproxy backends for ${host}",
      contact_groups => ['alerts'],
    }
    nagioscfg::service {"check_website_status${host}":
      host_name      => ["${host}"],
      use            => 'monitor-service',
      check_command  => "check_website_string!https://${host}/status!OK",
      description    => "check status for https://${host}/status",
      contact_groups => ['alerts'],
    }
  }
  nagioscfg::service {'check_public_ssl_cert':
    host_name      => $public_hosts,
    use            => 'monitor-service',
    check_command  => 'check_ssl_cert_3!30!14!443',
    description    => 'check https certificate validity on port 443',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'check_infra_ssl_cert':
    host_name      => $md_haproxy_hosts + $meta_hosts + $static_haproxy_hosts,
    use            => 'monitor-service',
    check_command  => 'check_ssl_cert_3_without_ocsp!30!14!443',
    description    => 'check https infra certificate validity on port 443',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'static_check_web_clustercheck':
    host_name      => [localhost],
    use            => 'monitor-service',
    check_command  => 'check_service_cluster!"check web"!0!1!$SERVICESTATEID:static.aws1.geant.eu.seamlessaccess.org:check web$,$SERVICESTATEID:static.aws2.geant.eu.seamlessaccess.org:check web$,$SERVICESTATEID:static.ntx.sunet.eu.seamlessaccess.org:check web$,$SERVICESTATEID:static.se-east.sunet.eu.seamlessaccess.org:check web$',
    description    => 'check web - static clustercheck',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'md_check_web_clustercheck':
    host_name      => [localhost],
    use            => 'monitor-service',
    check_command  => 'check_service_cluster!"check web"!0!1!$SERVICESTATEID:md.aws1.geant.eu.seamlessaccess.org:check web$,$SERVICESTATEID:md.aws2.geant.eu.seamlessaccess.org:check web$,$SERVICESTATEID:md.ntx.sunet.eu.seamlessaccess.org:check web$,$SERVICESTATEID:md.se-east.sunet.eu.seamlessaccess.org:check web$',
    description    => 'check web - md clustercheck',
    contact_groups => ['alerts']
  }
  nagioscfg::service {'md_check_metadata_clustercheck':
    host_name      => [localhost],
    use            => 'monitor-service',
    check_command  => 'check_service_cluster!"check metadata"!0!1!$SERVICESTATEID:md.aws1.geant.eu.seamlessaccess.org:check metadata for md.aws1.geant.eu.seamlessaccess.org$,$SERVICESTATEID:md.aws2.geant.eu.seamlessaccess.org:check metadata for md.aws2.geant.eu.seamlessaccess.org$,$SERVICESTATEID:md.ntx.sunet.eu.seamlessaccess.org:check metadata for md.ntx.sunet.eu.seamlessaccess.org$,$SERVICESTATEID:md.se-east.sunet.eu.seamlessaccess.org:check metadata for md.se-east.sunet.eu.seamlessaccess.org$', 
    description    => 'check metadata - md clustercheck',
    contact_groups => ['alerts']
  }
  $md_urls = concat ([ 'md.thiss.io', 'md.seamlessaccess.org', 'md-staging.thiss.io'] , $md_haproxy_hosts)
  $md_urls.each |$url|{
    nagioscfg::service {"check_metadata_age_${url}":
      host_name      => ["${url}"],
      use            => 'monitor-service',
      check_command  => "check_metadata_age!https://${url}",
      description    => "check metadata for ${url}",
      contact_groups => ['alerts'],
    }
    nagioscfg::service {"check_metadata_sp_age_${url}":
      host_name      => ["${url}"],
      use            => 'monitor-service',
      check_command  => "check_metadata_sp_age!https://${url}",
      description    => "check SP trust metadata for ${url}",
      contact_groups => ['alerts'],
    }
  }
  $md_hosts = ['md-1.ntx.sunet.eu.seamlessaccess.org', 'md-1.se-east.sunet.eu.seamlessaccess.org', 'md-1.aws1.geant.eu.seamlessaccess.org', 'md-1.aws2.geant.eu.seamlessaccess.org','md-2.ntx.sunet.eu.seamlessaccess.org', 'md-2.se-east.sunet.eu.seamlessaccess.org', 'md-2.aws1.geant.eu.seamlessaccess.org', 'md-2.aws2.geant.eu.seamlessaccess.org', 'md-1.thiss.io', 'md-2.thiss.io']
  $md_hosts.each |$host|{
    nagioscfg::service {"check_metadata_age_${host}":
      host_name      => ["${host}"],
      use            => 'monitor-service',
      check_command  => "check_metadata_age!http://${host}",
      description    => "check metadata for ${host}",
      contact_groups => ['alerts'],
    }
    nagioscfg::service {"check_metadata_sp_age_${host}":
      host_name      => ["${host}"],
      use            => 'monitor-service',
      check_command  => "check_metadata_sp_age!http://${host}",
      description    => "check SP trust metadata for ${host}",
      contact_groups => ['alerts'],
    }
    nagioscfg::service {"check_website_status${host}":
      host_name      => ["${host}"],
      use            => 'monitor-service',
      check_command  => "check_website_http!http://${host}/status!OK",
      description    => "check web for ${host}",
      contact_groups => ['alerts'],
    }
  }
  $static_hosts = ['static-1.aws2.thiss.io', 'static-2.aws2.thiss.io', 'static-1.thiss.io', 'static-1.ntx.sunet.eu.seamlessaccess.org', 'static-1.se-east.sunet.eu.seamlessaccess.org', 'static-1.aws1.geant.eu.seamlessaccess.org', 'static-1.aws2.geant.eu.seamlessaccess.org', 'static-2.thiss.io', 'static-2.ntx.sunet.eu.seamlessaccess.org', 'static-2.se-east.sunet.eu.seamlessaccess.org', 'static-2.aws1.geant.eu.seamlessaccess.org', 'static-2.aws2.geant.eu.seamlessaccess.org']
  $static_hosts.each |$host|{
    nagioscfg::service {"check_${host}":
      host_name      => ["${host}"],
      use            => 'monitor-service',
      check_command  => "check_website_http!http://${host}/manifest.json!version",
      description    => 'check web',
      contact_groups => ['alerts'],
    }
  }
  nagioscfg::service {"check_sa_version_beta":
    hostgroup_name => ['thiss::static_beta'],
    use            => 'monitor-service',
    check_command  => "check_nrpe_1arg!check_sa_version",
    description    => 'check thiss-js version in Beta',
    contact_groups => ['alerts'],
  }
  nagioscfg::service {"check_sa_version_prod":
    hostgroup_name => ['thiss::static_prod'],
    use            => 'monitor-service',
    check_command  => "check_nrpe_1arg!check_sa_version",
    description    => 'check thiss-js version in Beta',
    contact_groups => ['alerts'],
  }
}

if $facts['networking']['fqdn'] =~ /^meta\.\S+\.seamlessaccess\.org$/ {
    file_line { 'cosmos_conf_meta_common':
      path => '/etc/cosmos/cosmos.conf',
      line => 'COSMOS_REPO_MODELS="$COSMOS_REPO/meta-common/:$COSMOS_REPO_MODELS"',
    }
  }
