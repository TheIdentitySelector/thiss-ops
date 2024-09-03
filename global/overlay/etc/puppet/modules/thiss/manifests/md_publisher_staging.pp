class thiss::md_publisher_staging($keyname=undef, String $dir="/var/www/html", String $watch="/var/www/html/entities/index.html", $watch_sp="/var/www/html/entities/index.html") {
   $_keyname = $keyname ? {
      undef   => "${::fqdn}_infra",
      default => $keyname
   }
   # this allows fileage check to work wo sudo
   file { '/var/www': ensure => directory, mode => '0755' } ->
   file { '/var/www/html': ensure => directory, mode => '0755', owner => 'www-data', group =>'www-data' } ->
   package {['lighttpd','attr']: ensure => latest } ->
   exec {'enable-ssl':
      command => "/usr/sbin/lighttpd-enable-mod ssl",
      onlyif  => "test ! -h /etc/lighttpd/conf-enabled/*ssl*"
   } ->
   file {'/etc/lighttpd/server.pem':
      ensure => 'link',
      target => "/etc/ssl/private/${_keyname}.pem"
   } ->
   if ($::operatingsystemrelease < '20.04') {
     apparmor::profile { 'usr.sbin.lighttpd': source => '/etc/apparmor-cosmos/usr.sbin.lighttpd' }
     }
   else {
     apparmor::profile { 'usr.sbin.lighttpd': source => '/etc/apparmor-cosmos/usr.sbin.lighttpd.upgraded' }
     }
   file {'/etc/lighttpd/conf-enabled/99-mime-xattr.conf':
      ensure  => file,
      mode    => '0640',
      owner   => 'root',
      group   => 'root',
      content => inline_template("mimetype.use-xattr = \"enable\"\n")
   } ->
   service {'lighttpd': ensure => running } ->
   sunet::nagios::nrpe_check_fileage {"metadata_aggregate":
      filename => $watch,
      warning_age => '2100',
      critical_age => '86400'
   }
   sunet::nagios::nrpe_check_fileage {"metadata_sp_aggregate":
      filename => $watch_sp,
      warning_age => '2100',
      critical_age => '86400'
   }
   $md_files = ['eduGAIN.xml', 'incommon.xml', 'openathens.xml', 'swamid-registered.xml']
   $md_files.each |$md_file|{
      sunet::nagios::nrpe_check_fileage {"${md_file}":
        filename => "/opt/pyff/metadata/${md_file}",
        warning_age => '2100',
        critical_age => '86400'
      }
    }
}

