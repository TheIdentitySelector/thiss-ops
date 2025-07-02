class thiss::mdq_beta($version='',
                 $src=undef,
                 $src_trust=undef,
                 $dst="/etc/thiss/metadata.json",
                 $dst_trust="/etc/thiss/metadata_sp.json",
                 $post="/bin/true",
                 $base_url=undef)
{

   $final_base_url = "BASE_URL=${base_url}"

   ensure_resource('file','/etc/thiss/', { ensure => directory } )

   file {$dst:
      ensure   => 'present',
      replace  => 'no',
      content  => "[]",
      mode     => '0644'
   } ->
   file {$dst_trust:
      ensure   => 'present',
      replace  => 'no',
      content  => "[]",
      mode     => '0644'
   } ->
   file { '/usr/local/bin/get_metadata.sh':
      content      => template('thiss/mdq/get_metadata_beta.erb'),
      owner        => root,
      group        => root,
      mode         => '0755'
   } ->
   sunet::scriptherder::cronjob { "${name}_fetch_metadata":
     cmd           => "/usr/local/bin/get_metadata.sh",
     minute        => '*/5',
     ok_criteria   => ['exit_status=0','max_age=48h'],
     warn_criteria => ['exit_status=1','max_age=50h'],
   } ->

   if $version {

      sunet::docker_compose {'thiss-mdq':
        service_name => 'thiss-mdq',
        description  => 'SA metadata query protocol',
        compose_dir  => '/opt/thiss_mdq/compose',
        content => template('thiss/mdq/thiss-mdq.yml.erb'),
      }
   }
}
