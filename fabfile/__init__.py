from fabric.api import run,env
from fabric.operations import get
import os
import yaml
import re

def _all_hosts():
   return filter(lambda fn: '.' in fn and not fn.startswith('.') and os.path.isdir(fn),os.listdir("."))

def _roledefs():
   rules = dict()

   rules_file = "cosmos-rules.yaml";
   if os.path.exists(rules_file):
      with open(rules_file) as fd:
         rules.update(yaml.load(fd))

   roles = dict() 
   for node_name in _all_hosts():
      for reg,cls in rules.iteritems():
         if re.search(reg,node_name):
            for cls_name in cls.keys():
               h = roles.get(cls_name,[])
               h.append(node_name)
               roles[cls_name] = h
   return roles

env.user = 'root'
env.timeout = 30
env.connection_attempts = 3
env.warn_only = True
env.skip_bad_hosts = True
env.roledefs = _roledefs()

print repr(env.roledefs)

def all():
    env.hosts = _all_hosts()

def cosmos():
    run("cosmos update && cosmos apply");

def upgrade():
    run("apt-get -qq update && apt-get -y -q dist-upgrade");

def facts():
    get("/var/run/facts.yaml",local_path="facts/%(host)s.yaml")

def chassis():
    run("ipmi-chassis --get-chassis-status")

def newvm(fqdn,ip,domain):
    run("vmbuilder kvm ubuntu --domain %s --dest /var/lib/libvirt/images/%s.img --arch x86_64 --hostname %s --mem 512 --ip %s --addpkg openssh-server" % (domain,fqdn,fqdn,ip))
