class thiss::demo_sp($version='latest')
{
  sunet::docker_run { 'always-https':
    image => 'docker.sunet.se/always-https',
    ports => ['80:80'],
    env   => ['ACME_URL=http://acme-c.sunet.se/'],
  }

  sunet::docker_run { 'demo-sp':
    hostname            => "${::fqdn}",
    image               => 'docker.sunet.se/swamid/metadata-sp',
    imagetag            => $version,
    env                 => ['SP_METADATAFEED=http://mds.swamid.se/md/swamid-idp-transitive.xml'],
    volumes             => ['/var/www:/var/www',
                            "/etc/dehydrated/certs/${::fqdn}:/etc/dehydrated",
                            '/etc/shibboleth/certs:/etc/shibboleth/certs'],
    ports               => ['443:443'],
    uid_gid_consistency => false
  }
}
