# Wrapper with thiss common settings for sunet::cloudimage
define thiss::cloudimage(
  String           $mac,
  String           $cpus        = '1',
  String           $memory      = '1024',
  String           $description = undef,
  Optional[String] $ip          = undef,
  Optional[String] $netmask     = undef,
  Optional[String] $gateway     = undef,
  Optional[String] $ip6         = undef,
  Optional[String] $netmask6    = '64',
  Optional[String] $gateway6    = undef,
  Array[String]    $search      = ['komreg.net'],
  String           $bridge      = 'br0',
  String           $size        = '40G',
  String           $local_size  = '0',
  String           $image_url   = 'https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img',
) {
  # This is a hack, use SSH keys from KVM host?
  $_ssh_key = hiera('ssh_authorized_keys')['berra+96E0A9D4']
  $cloudimage_ssh_keys = [sprintf('%s %s %s', $_ssh_key['type'], $_ssh_key['key'], $_ssh_key['name'])]

  sunet::cloudimage { $name:
    image_url   => $image_url,
    ssh_keys    => $cloudimage_ssh_keys,
    apt_dir     => '/etc/cosmos/apt',
    disable_ec2 => true,
    #
    bridge      => $bridge,
    dhcp        => false,
    mac         => $mac,
    ip          => $ip,
    netmask     => $netmask,
    gateway     => $gateway,
    ip6         => $ip6,
    netmask6    => $netmask6,
    gateway6    => $gateway6,
    resolver    => ['130.242.80.14', '130.242.80.99'],
    search      => $search,
    #
    repo        => $::cosmos_repo_origin_url,
    tagpattern  => $::cosmos_tag_pattern,
    #
    cpus        => $cpus,
    memory      => $memory,
    description => $description,
    size        => $size,
    local_size  => $local_size,
  }
}
