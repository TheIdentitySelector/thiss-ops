class thiss::pyffd($pyff_version="latest") {
  $image_tag = "docker.sunet.se/pyff:${pyff_version}"
  file {"/opt/pyff": ensure => directory } ->
  sunet::scriptherder::cronjob { "mirror": 
    cmd               => "/bin/true",
    ensure            => absent
  } ->
  sunet::scriptherder::cronjob { "publish":
    ensure            => absent,
    cmd               => "/bin/true"
  }
  package { 'lighttpd': ensure => removed } -> service {'lighttpd': ensure => stopped }
  sunet::pyffd {'mdq':
     version           => $pyff_version,
     dir               => "/opt/pyff",
  }
}
