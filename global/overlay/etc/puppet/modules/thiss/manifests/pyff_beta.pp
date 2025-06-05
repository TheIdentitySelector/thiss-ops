class thiss::pyff_beta($pyff_version="thiss",$output="/etc/thiss/metadata.json",$output_trust="/etc/thiss/metadata_sp.json") {
  $image_tag = "docker.sunet.se/pyff:${pyff_version}"
  $pipeline = hiera("pyff_pipeline_beta")

  package {'xmlsec1': ensure => present}

  $image_find = "docker images |grep docker.sunet.se/pyff |grep ${image_tag}"

  exec { 'pull_docker_images':
    command      => "docker pull ${image_tag}",
    unless       => $image_find,
    require      => Class['sunet::dockerhost2'],
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
    cmd               => "/usr/local/sbin/run-pyff /opt/pyff/mdx.fd $output $output_trust",
    minute            => '*/30',
    ok_criteria       => ['exit_status=0'],
    warn_criteria     => ['max_age=30m']
  }
}
