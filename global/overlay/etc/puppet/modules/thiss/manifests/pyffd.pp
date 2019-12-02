class thiss::pyffd($pyff_version="thiss") {
  $pipeline = hiera("pyffd_pipeline")
  $image_tag = "docker.sunet.se/pyff:${pyff_version}"
  file {["/etc/thiss","/opt/pyff"]: ensure => directory } ->
  file {"/usr/local/sbin/run-pyff":
     content => template("thiss/pyff/run-pyff.erb"),
     mode    => '0755'
  } ->
  file {"/opt/pyff/mdx.fd":
     content => inline_template("<%= @pipeline.to_yaml %>\n")
  }
  sunet::scriptherder::cronjob { "mirror": 
    cmd               => "/usr/local/bin/mirror-mdq.sh http://localhost/ /var/www/html/",
    minute            => '*/30',
    ok_criteria       => ['exit_status=0'],
    warn_criteria     => ['max_age=30m']
  } ->
  sunet::scriptherder::cronjob { "publish":
    ensure            => absent,
    cmd               => "/bin/true"
  }
  sunet::pyff {'mdq':
     version          => $pyff_version,
     ip               => "127.0.0.1",
     dir              => "/opt/pyff"
  }
}
