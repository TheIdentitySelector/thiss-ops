class thiss::pyffd($pyff_version="latest") {
  $image_tag = "docker.sunet.se/pyff:${pyff_version}"
  file {"/opt/pyff": ensure => directory } ->
  sunet::scriptherder::cronjob { "mirror": 
    cmd               => "/usr/local/bin/mirror-mdq.sh http://localhost:8080 /var/www/html/",
    minute            => '*/30',
    ok_criteria       => ['exit_status=0'],
    warn_criteria     => ['max_age=30m']
  } ->
  sunet::scriptherder::cronjob { "publish":
    ensure            => absent,
    cmd               => "/bin/true"
  }
  sunet::pyff {'mdq':
     version           => $pyff_version,
     ip                => "127.0.0.1",
     port              => "8080",
     dir               => "/opt/pyff",
     pound_and_varnish => false
  }
}
