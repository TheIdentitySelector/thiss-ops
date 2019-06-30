class thiss::md_publisher(Array $allow_clients=['any'], $keyname=undef, String $dir="/var/www/html", String $watch = "/var/www/html/entities/index.html") {
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
      filename => $watch,
      warning_age => '600',
      critical_age => '86400'
   }
}

