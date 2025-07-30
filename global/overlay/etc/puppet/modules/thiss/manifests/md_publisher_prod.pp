class thiss::md_publisher_prod(
   String $publisher_cert="/etc/ssl/certs/${facts['networking']['fqdn']}_infra.crt",
   String $publisher_key="/etc/ssl/private/${facts['networking']['fqdn']}_infra.key",
   String $dir="/var/www/html",
   String $watch="/var/www/html/entities/index.html",
   String $watch_sp="/var/www/html/entities/index.html",
   String $imagetag='',) {

   # this allows fileage check to work wo sudo
   file { '/var/www': ensure => directory, mode => '0755' } ->
   file { '/var/www/html': ensure => directory, mode => '0755', owner => 'www-data', group =>'www-data' } ->

   if $imagetag {

      sunet::docker_compose { 'md_publisher':
        content          => template('thiss/md_publisher/docker-compose.yml.erb'),
        service_name     => 'md_publisher',
        compose_dir      => '/opt/',
        compose_filename => 'docker-compose.yml',
        description      => 'Metadata Query Protocol Publisher',
      }
   }
   else notice ("No image tag is found, md_publisher won't be running!")

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

