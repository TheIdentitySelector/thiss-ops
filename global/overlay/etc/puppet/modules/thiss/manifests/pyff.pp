class thiss::pyff($pyff_version="thiss",$output="/etc/thiss/metadata.json,$output_trust="/etc/thiss/metadata_sp.json") {
  $image_tag = "docker.sunet.se/pyff:${pyff_version}"
  $pipeline = hiera("pyff_pipeline")
  $pipeline_trust = hiera("pyff_pipeline_trust")

  package {'xmlsec1': ensure => present}

  docker::image { "${image_tag}" :
    image   => $image_tag,
    require => Class['sunet::dockerhost'],
  } ->
  file {["/etc/thiss","/opt/pyff","/opt/pyff/metadata"]: ensure => directory } ->
  file {"/usr/local/sbin/run-pyff":
     content => template("thiss/pyff/run-pyff.erb"),
     mode    => '0755'
  } ->
  file {"/opt/pyff/mdx.fd":
     content => inline_template("<%= @pipeline.to_yaml %>\n")
  }
  file {"/opt/pyff/mdx_trust.fd":
     content => inline_template("<%= @pipeline_trust.to_yaml %>\n")
  }
  sunet::scriptherder::cronjob { "publish":
    cmd               => "/usr/local/sbin/run-pyff /opt/pyff/mdx.fd /opt/pyff/mdx_trust.fd $output $output_trust",
    minute            => '*/30',
    ok_criteria       => ['exit_status=0'],
    warn_criteria     => ['max_age=30m']
  }
}