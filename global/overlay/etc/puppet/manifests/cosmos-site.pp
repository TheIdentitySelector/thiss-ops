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

class jumphosts {}

class infra_ca_rp {
   sunet::ici_ca::rp { 'infra': }
}

# you need a default node, all nodes need ssh + ufw
node default {
}

class site_alias($alias_name=undef) {
   file { "/var/www/$alias_name":
      ensure => link,
      target => $name
   }
}

class common {
  include sunet::tools
  include sunet::motd
  include sunet::ntp
  include ufw
  include apt
  include apparmor
  package {'jq': ensure => 'latest'}
  package { 'needrestart': ensure => installed}

  if $::is_virtual == true {
    file { '/usr/local/bin/sunet-reinstall':
      ensure  => file,
      mode    => '0755',
      content => template('sunet/cloudimage/sunet-reinstall.erb'),
    }
  }
}

class dhcp6_client {
  ufw::allow { "allow-dhcp6-546":
      ip    => 'any',
      port  => '546',
      proto => 'udp',
  }
  ufw::allow { "allow-dhcp6-547":
      ip    => 'any',
      port  => '547',
      proto => 'udp'
  }
}

class entropyclient {
   include sunet::simple_entropy
   sunet::ucrandom {'random.nordu.net': }
   sunet::nagios::nrpe_check_process { 'haveged': }
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

class sunet_iaas_cloud {
   sunet::cloud_init::config { 'disable_datasources':
      config => { datasource_list => [ 'None' ] }
   }
   sunet::cloud_init::config { 'keep_root_enabled':
      config => { disable_root => 'false' }
   }
}

class webserver {
   ufw::allow { "allow-http":
      ip   => 'any',
      port => '80'
   }
   ufw::allow { "allow-https":
      ip   => 'any',
      port => '443'
   }
}

class servicemonitor {
   $nagios_ip_v4 = join(hiera('nagios_ip_v4')," ");
   ufw::allow { "allow-servicemonitor-from-nagios":
      ip   => $nagios_ip_v4,
      port => '444',
      ensure => absent
   }
}

class https_server {

}

class saml_metadata($filename=undef, $cert=undef, $url=undef) {
  sunet::metadata { "$filename": url => $url, cert => $cert }
}

class md_repo_client {
   sunet::snippets::reinstall::keep {['/etc/metadata','/root/.ssh']: } ->
   sunet::ssh_git_repo {'/var/cache/metadata_r1':
      username    => 'root',
      group       => 'root',
      hostname    => 'r1.komreg.net',
      url         => 'git@r1.komreg.net:komreg-metadata.git',
      id          => 'komreg',
      manage_user => false
   } ->
   package { ['make']: ensure => latest } ->
   sunet::scriptherder::cronjob { 'verify_and_update':
      cmd           => '/var/cache/metadata_r1/scripts/do-update.sh',
      minute        => '*/5',
      ok_criteria   => ['exit_status=0', 'max_age=15m'],
      warn_criteria => ['exit_status=0', 'max_age=1h'],
   }
}

class md_signer($dest_host=undef,$dest_dir="",$version="eidas") {
   package { ['xsltproc','libxml2-utils','attr']: ensure => latest } ->
   sunet::pyff {$name:
      version           => $version,
      pound_and_varnish => false,
      pipeline          => "${name}.fd",
      volumes           => ["/etc/credentials:/etc/credentials"],
      docker_run_extra_parameters => ["--log-driver=syslog"]
   }
   if ($dest_host) {
      sunet::ssh_host_credential { "${name}-publish-credential":
         hostname          => $dest_host,
         username          => 'root',
         group             => 'root',
         manage_user       => false,
         ssh_privkey       => safe_hiera("publisher_ssh_privkey")
      } ->
      sunet::scriptherder::cronjob { "${name}-publish":
         cmd               => "env RSYNC_ARGS='--chown=www-data:www-data --chmod=D0755,F0664 --xattrs' /usr/local/bin/mirror-mdq.sh http://localhost root@${dest_host}:${dest_dir}",
         minute            => '*/5',
         ok_criteria       => ['exit_status=0'],
         warn_criteria     => ['max_age=30m']
      }
   }
}

class md_publisher(Array $allow_clients=['any'], $keyname=undef, String $dir="/var/www/html") {
   $_keyname = $keyname ? { 
      undef   => $::fqdn,
      default => $keyname
   }
   # this allows fileage check to work wo sudo
   file { '/var/www': ensure => directory, mode => '0755' } ->
   file { '/var/www/html': ensure => directory, mode => '0755', owner => 'www-data', group =>'www-data' } ->
   sunet::rrsync {$dir:
      ro                => false,
      ssh_key           => safe_hiera('publisher_ssh_key'),
      ssh_key_type      => safe_hiera('publisher_ssh_key_type')
   } ->
   package {['lighttpd','attr']: ensure => latest } ->
   exec {'enable-ssl': 
      command => "/usr/sbin/lighttpd-enable-mod ssl",
      onlyif  => "test ! -h /etc/lighttpd/conf-enabled/*ssl*"
   } ->
   file {'/etc/lighttpd/server.pem':
      ensure => 'link',
      target => "/etc/ssl/private/${_keyname}.pem"
   } ->
   apparmor::profile { 'usr.sbin.lighttpd': source => '/etc/apparmor-cosmos/usr.sbin.lighttpd' } ->
   file {'/etc/lighttpd/conf-enabled/99-mime-xattr.conf':
      ensure  => file,
      mode    => '0640',
      owner   => 'root',
      group   => 'root',
      content => inline_template("mimetype.use-xattr = \"enable\"\n")
   } ->
   service {'lighttpd': ensure => running } ->
   sunet::misc::ufw_allow {'allow-lighttpd':
      from   => $allow_clients,
      port   => 443
   } ->
   sunet::nagios::nrpe_check_fileage {"metadata_aggregate":
      filename => "/var/www/html/entities/index.html", # yes this is correct
      warning_age => '600',
      critical_age => '86400'
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
  # Allow hosts to configure sshd as needed
  $sshd_config = $hostname ? {
    'pypi'  => false,
    default => true,
  }
  class { 'sunet::server':
    sshd_config => $sshd_config,
  }

  # SSH config, create SSH authorized keys from Hiera
  $ssh_authorized_keys = hiera_hash('ssh_authorized_keys', undef)
  if is_hash($ssh_authorized_keys) {
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
  if $::hostname =~ /kvm/ {
    class {'bastion':
      fstab_fix_shm        => false,
      sysctl_net_hardening => false,
    }
  } elsif $::hostname =~ /random/ {  # pollen requires exec on /tmp
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
   if ($::operatingsystem == 'Ubuntu' and $::operatingsystemrelease == '12.04') {
      class {'apt::backports': }
   }
   package {'nagios-plugins-contrib': ensure => latest}
   if ($::operatingsystem == 'Ubuntu' and $::operatingsystemrelease < '18.04') {
      package {'nagios-plugins-extra': ensure => latest}
   }
   sunet::nagios::nrpe_command {'check_memory':
      command_line => '/usr/lib/nagios/plugins/check_memory -w 10% -c 5%'
   }
   sunet::nagios::nrpe_command {'check_mem':
      command_line => '/usr/lib/nagios/plugins/check_memory -w 10% -c 5%'
   }
   sunet::nagios::nrpe_command {'check_boot_15_5':
      command_line => '/usr/lib/nagios/plugins/check_disk -w 15% -c 5% -p /boot'
   }
   sunet::nagios::nrpe_command {'check_entropy':
      command_line => '/usr/lib/nagios/plugins/check_entropy'
   }
   sunet::nagios::nrpe_command {'check_ntp_time':
      command_line => '/usr/lib/nagios/plugins/check_ntp_time -H localhost'
   }
   sunet::nagios::nrpe_command {'check_scriptherder':
      command_line => '/usr/local/bin/scriptherder --mode check'
   }
   sunet::nagios::nrpe_command {'check_apt':
      command_line => '/usr/lib/nagios/plugins/check_apt'
   }
   sunet::nagios::nrpe_command {'check_eidas_health':
      command_line => '/usr/lib/nagios/plugins/check_eidas_health.sh localhost'
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
   
   class { 'webserver': }
   class { 'nagioscfg':
      hostgroups      => $::roles,
      config          => 'eid'
   }
   class {'nagioscfg::slack': domain => 'sunet.slack.com', token => safe_hiera('slack_token','') } ->
   class {'nagioscfg::passive': enable_notifications => '1', obsess_over_hosts => '0'}

   sunet::misc::htpasswd_user { $web_admin_user :
      filename => "/etc/nagios3/htpasswd.users",
      password => $web_admin_pw,
      group    => 'www-data',
    }

   file {
      '/root/MONITOR_WEB_PASSWORD':
        content => sprintf("%s\n%s\n", $web_admin_user, $web_admin_pw),
        group   => 'root',
        mode    => '0600',
        ;
   }
   nagioscfg::slack::channel {'eln': } ->
   nagioscfg::contactgroup {'alerts': } ->
   nagioscfg::contact {'slack-alerts':
      host_notification_commands    => ['notify-host-to-slack-eln'],
      service_notification_commands => ['notify-service-to-slack-eln'],
      contact_groups                => ['alerts']
   }
   nagioscfg::service {'service_ping':
      hostgroup_name => ['all'],
      description    => 'PING',
      check_command  => 'check_ping!400.0,1%!500.0,2%',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'service_ssh':
      hostgroup_name => ['jumphosts'],
      description    => 'SSH',
      check_command  => 'check_ssh_4_hostname',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_load':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_load',
      description    => 'System Load',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_users':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_users',
      description    => 'Active Users',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_zombie_procs':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_zombie_procs',
      description    => 'Zombie Processes',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_total_procs':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_total_procs_lax',
      description    => 'Total Processes',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_root':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_root',
      description    => 'Root Disk',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_boot':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_boot_15_5',
      description    => 'Boot Disk',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_var':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_var',
      description    => 'Var Disk',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_uptime':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_uptime',
      description    => 'Uptime',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_reboot':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_reboot',
      description    => 'Reboot Needed',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_memory':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_memory',
      description    => 'System Memory',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_entropy':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_entropy',
      description    => 'System Entropy',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_ntp_time':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_ntp_time',
      description    => 'System NTP Time',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_process_haveged':
      hostgroup_name => ['entropyclient'],
      check_command  => 'check_nrpe_1arg!check_process_haveged',
      description    => 'haveged running',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_scriptherder':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_scriptherder',
      description    => 'Scriptherder Status',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_apt':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_apt',
      description    => 'Packages available for upgrade',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'metadata_aggregate_age':
      hostgroup_name => ['md_publisher'],
      check_command  => 'check_nrpe_1arg!check_fileage_metadata_aggregate',
      description    => 'metadata aggregate age',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'mdsl_aggregate_age':
      hostgroup_name => ['mdsl_publisher'],
      check_command  => 'check_nrpe_1arg!check_fileage_mdsl_aggregate',
      description    => 'mdsl aggregate age',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'mdsl_se_age':
      hostgroup_name => ['mdsl_publisher'],
      check_command  => 'check_nrpe_1arg!check_fileage_mdsl_se',
      description    => 'mdsl se age',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_eidas_health':
      hostgroup_name => ['servicemonitor'],
      check_command  => 'check_nrpe_1arg!check_eidas_health',
      description    => 'eidas component healthcheck',
      contact_groups => ['alerts']
   }
   nagioscfg::service {'check_needrestart':
      hostgroup_name => ['nrpe'],
      check_command  => 'check_nrpe_1arg!check_needrestart',
      description    => 'Processes need restart',
      contact_groups => ['alerts']
   }
   nagioscfg::command {'check_ssl_cert_3':
      command_line   => "/usr/lib/nagios/plugins/check_ssl_cert -A -H '\$HOSTADDRESS\$' -c '\$ARG2\$' -w '\$ARG1\$' -p '\$ARG3\$'"
   }
   $public_hosts = ['swedenconnect.se','qa.test.swedenconnect.se','qa.md.swedenconnect.se','md.swedenconnect.se','md.eidas.swedenconnect.se','qa.md.eidas.swedenconnect.se','qa.connector.eidas.swedenconnect.se','qa.proxy.eidas.swedenconnect.se','connector.eidas.swedenconnect.se']
   nagioscfg::host {$public_hosts: }
   nagioscfg::service {'check_public_ssl_cert':
      host_name      => $public_hosts,
      check_command  => 'check_ssl_cert_3!30!14!443',
      description    => 'check https certificate validity on port 443',
      contact_groups => ['alerts']
   }
   nagioscfg::command {'check_website':
      command_line   => "/usr/lib/nagios/plugins/check_http -H '\$HOSTNAME\$' -S -u '\$ARG1\$'"
   }
   nagioscfg::service {'check_metadata_eIDAS':
      host_name      => ['md.eidas.swedenconnect.se'],
      check_command  => 'check_website!https://md.eidas.swedenconnect.se/',
      description    => 'check metadata for eIDAS',
      contact_groups => ['alerts'],
   }
   nagioscfg::service {'check_metadata_swedenconnect':
      host_name      => ['md.swedenconnect.se'],
      check_command  => 'check_website!https://md.swedenconnect.se/',
      description    => 'check metadata for Sweden Connect',
      contact_groups => ['alerts'],
  }
  nagioscfg::service {'check_connector':
      host_name      => ['connector.eidas.swedenconnect.se'],
      check_command  => 'check_website!https://connector.eidas.swedenconnect.se/idp/metadata/sp',
      description    => 'check metadata for Sweden Connect',
      contact_groups => ['alerts'],
   }
}

class redis_cluster_node {
   file { '/opt/redis': ensure => directory }
   sysctl { 'vm.overcommit_memory': value => '1' }
   sunet::redis::server {'redis-master':
      allow_clients => hiera_array('redis_client_ips', []),
      cluster_nodes => hiera_array('redis_sentinel_ips', []),
   }
   sunet::redis::server {'redis-sentinel':
      port            => '26379',
      sentinel_config => 'yes',
      allow_clients   => hiera_array('redis_client_ips', []),
      cluster_nodes   => hiera_array('redis_sentinel_ips', []),
   }
}

class redis_frontend_node ($hostname=undef,$ca="infra") {
   file { '/opt/redis': ensure => directory }
   sunet::redis::haproxy {'redis-haproxy':
      cluster_nodes => hiera_array('redis_sentinel_ips', []),
      client_ca     => "/etc/ssl/certs/${ca}.crt",
      certificate   => "/etc/ssl/private/${::fqdn}_${ca}.pem"
   }
}
