# This manifest is managed using cosmos

Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
}

# include some of this stuff for additional features

#include cosmos::tools
#include cosmos::motd
#include cosmos::ntp
#include cosmos::rngtools
#include cosmos::preseed
#include ufw
#include apt
#include cosmos

# you need a default node

node default {

}

# edit and uncomment to manage ssh root keys in a simple way

#class { 'cosmos::access':
#   keys => [
#      "ssh-rsa ..."
#   ]
#}

# example config for the nameserver class which is matched in cosmos-rules.yaml

#class nameserver {
#   package {'bind9':
#      ensure => latest
#   }
#   service {'bind9':
#      ensure => running
#   }
#   ufw::allow { "allow-dns-udp":
#      ip   => 'any',
#      port => 53,
#      proto => "udp"
#   }
#   ufw::allow { "allow-dns-tcp":
#      ip   => 'any',
#      port => 53,
#      proto => "tcp"
#   }
#}
