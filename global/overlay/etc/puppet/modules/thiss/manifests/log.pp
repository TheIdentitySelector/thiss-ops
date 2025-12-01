class thiss::log{

  sunet::rrsync { '/var/log/':
    ssh_key_type       => 'ssh-ed25519',
    ssh_key            => $enrique_ssh_key,
    use_sunet_ssh_keys => true,
  }
}