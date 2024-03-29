class thiss::pyff_beta($pyff_version="thiss",$output="/etc/thiss/metadata.json") {
  $image_tag = "docker.sunet.se/pyff:${pyff_version}"
  $pipeline = hiera("pyff_pipeline_beta")
  
  docker::image { "${image_tag}" :
    image   => $image_tag,
    require => Class['sunet::dockerhost'],
  } ->
  file {["/etc/thiss","/opt/pyff","/opt/pyff/metadata"]: ensure => directory } ->
  file {"/usr/local/sbin/run-pyff":
     content => template("thiss/pyff/run-pyff_beta.erb"),
     mode    => '0755'
  } ->
  file {"/opt/pyff/mdx.fd":
     content => inline_template("<%= @pipeline.to_yaml %>\n")
  }
  
  sunet::scriptherder::cronjob { "publish":
    cmd               => "/usr/local/sbin/run-pyff /opt/pyff/mdx.fd $output",
    minute            => '*/30',
    ok_criteria       => ['exit_status=0'],
    warn_criteria     => ['max_age=30m']
  }
}
