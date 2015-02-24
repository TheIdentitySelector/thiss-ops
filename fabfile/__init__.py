from fabric.api import run,env
from fabric.operations import get,put
import os
import yaml
import re
import sys
from fabfile.db import cosmos_db

env.user = 'root'
env.timeout = 30
env.connection_attempts = 3
env.warn_only = True
env.skip_bad_hosts = True
env.roledefs = cosmos_db()['members']

def all():
    env.hosts = cosmos_db()['members']['all']

def cosmos():
    run("/usr/local/bin/run-cosmos");

def upgrade():
    run("apt-get -qq update && apt-get -y -q dist-upgrade");

def facts():
    get("/var/run/facts.yaml",local_path="facts/%(host)s.yaml")

def chassis():
    run("ipmi-chassis --get-chassis-status")

def newvm(fqdn,ip,domain):
    run("vmbuilder kvm ubuntu --domain %s --dest /var/lib/libvirt/images/%s.img --arch x86_64 --hostname %s --mem 512 --ip %s --addpkg openssh-server" % (domain,fqdn,fqdn,ip))

def cp(local,remote):
    put(local,remote)
