class thiss::log (
  Sensitive[String] $hmac_salt,
  Sensitive[String] $htpasswd,
  String            $enrique_ssh_key,
  String            $enrique_ip,
  String            $analyzer_tag,
  String            $web_tag,
  Integer           $bucket_seconds     = 3600,
  Integer           $session_ttl        = 1800,
  Integer           $batch_interval     = 120,
  Integer           $max_batch_bytes    = 67108864,
  Integer           $report_max_buckets = 72,
  String            $truncate_mode      = 'collapse',
  String            $report_host        = $facts['networking']['fqdn'],
) {

  sunet::rrsync { '/var/log/':
    ssh_key_type       => 'ssh-rsa',
    ssh_key            => $enrique_ssh_key,
  }

  sunet::nftables::rule { 'allow_rsync':
    rule => "add rule inet filter input ip saddr {${enrique_ip}} tcp dport 22 counter accept comment \"allow-rsync-for-enrique\""
  }

  sunet::docker_compose { 'log_analyzer_docker_compose':
    content          => template('thiss/log/docker-compose.yml.erb'),
    service_name     => 'log_analyzer',
    compose_dir      => '/opt/analyze/',
    compose_filename => 'docker-compose.yml',
    description      => 'Log analyzer components',
  }

  file { '/opt/analyze/secrets/hmac_salt':
    ensure  => file,
    content => $hmac_salt.unwrap,
    mode    => '0600',
  }

  file { '/opt/analyze/web/auth/.htpasswd':
    ensure  => file,
    content => $htpasswd.unwrap,
    mode    => '0640',
  }

}
