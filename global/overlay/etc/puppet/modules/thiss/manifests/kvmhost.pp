class thiss::kvmhost(
  String $proxy_server = hiera('eid_proxy_server'),
  Boolean $no_proxy     = hiera('eid_no_proxy'),
  Hash   $vms          = [],
) {
  file {
    '/etc/cosmos-manual-reboot':
      ensure => present,
      ;
    '/etc/cosmos/apt/bootstrap-cosmos.sh':
      ensure  => 'file',
      mode    => '0755',
      content => template('eid/kvm/bootstrap-cosmos.sh.erb'),
      ;
  }

  package { ['bridge-utils',
             'vlan',
             ]: ensure => 'present' }

  exec { 'fix_iptables_forwarding_for_guests':
    command => 'sed -i "/^COMMIT/i-I FORWARD -m physdev --physdev-is-bridged -j ACCEPT" /etc/ufw/before.rules; ufw reload',
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin', ],
    unless  => 'grep -q -- "^-I FORWARD -m physdev --physdev-is-bridged -j ACCEPT" /etc/ufw/before.rules',
    onlyif  => 'test -f /etc/ufw/before.rules',
  }

  exec { 'fix_ip6tables_forwarding_for_guests':
    command => 'sed -i "/^COMMIT/i-I FORWARD -m physdev --physdev-is-bridged -j ACCEPT" /etc/ufw/before6.rules; ufw reload',
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin', ],
    unless  => 'grep -q -- "^-I FORWARD -m physdev --physdev-is-bridged -j ACCEPT" /etc/ufw/before6.rules',
    onlyif  => 'test -f /etc/ufw/before6.rules',
  }

  sunet::snippets::file_line {
    'load_vlan_module_at_boot':
      filename => '/etc/modules',
      line     => '8021q',
      ;
  }

  create_resources('eid::cloudimage', $vms)
}
