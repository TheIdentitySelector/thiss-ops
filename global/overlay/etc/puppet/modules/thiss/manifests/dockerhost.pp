# Wrapper for sunet::dockerhost to do thiss specific things
class thiss::dockerhost(
  String $version              = safe_hiera('eid_docker_version'),
  String $package_name         = hiera('eid_docker_package_name', 'docker-ce'),
  Enum['stable', 'edge', 'test'] $docker_repo = hiera('eid_docker_repo', 'stable'),
  String $compose_version      = safe_hiera('eid_docker_compose_version'),
  String $docker_args          = '',
  Optional[String] $docker_dns = undef,
) {
  if $version == 'NOT_SET_IN_HIERA' {
    fail('Docker version not set in Hiera')
  }
  if $compose_version == 'NOT_SET_IN_HIERA' {
    fail('Docker-compose version not set in Hiera')
  }
  class { 'sunet::dockerhost':
    docker_version            => $version,
    docker_package_name       => $package_name,
    docker_repo               => $docker_repo,
    run_docker_cleanup        => true,
    manage_dockerhost_unbound => true,
    docker_extra_parameters   => $docker_args,
    docker_dns                => $docker_dns,
    storage_driver            => 'aufs',
    docker_network            => true,  # let docker choose a network for the 'docker' bridge
    compose_version           => $compose_version,
  }
}
