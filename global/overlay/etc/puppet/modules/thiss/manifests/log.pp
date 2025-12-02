class thiss::log{

  $enrique_ssh_key = lookup ('enrique_ssh_key')
  $enrique_ip = lookup ('enrique_ip')

  sunet::rrsync { '/var/log/':
    ssh_key_type       => 'ssh-ed25519',
    ssh_key            => $enrique_ssh_key,
  }

  sunet::nftables::rule { 'allow_rsync':
    rule => "add rule inet filter input ip saddr {${enrique_ip}} tcp dport 22 counter accept comment \"allow-rsync-for-enrique\""
  }
}