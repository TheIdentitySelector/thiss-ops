class thiss::demo_sp($version='stable')
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
    #env                 => ['SP_METADATAFEED=http://mds.swamid.se/md/swamid-idp-transitive.xml'],
    volumes             => ['/var/www:/var/www:ro',
                            "/etc/dehydrated/certs/${::fqdn}:/etc/dehydrated:ro",
                            '/etc/shibboleth/certs:/etc/shibboleth/certs',
                            '/etc/apache2/start.sh:/start.sh',
                            '/etc/apache2/sites-available/default-ssl.conf:/etc/apache2/sites-available/default-ssl.conf:ro'],
    ports               => ['443:443'],
    uid_gid_consistency => false
  }
  vcsrepo { '/var/www/demo':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/TheIdentitySelector/thiss-demo'
  }
}
