import os
import yaml
import re

def _all_hosts():
   return filter(lambda fn: '.' in fn and not fn.startswith('.') and os.path.isdir(fn),os.listdir("."))

def _load_db():
   rules = dict()
   rules_file = "cosmos-rules.yaml";
   if os.path.exists(rules_file):
      with open(rules_file) as fd:
         rules.update(yaml.load(fd))
 
   all_hosts = _all_hosts()

   members = dict()
   for node_name in all_hosts:
      for reg,cls in rules.iteritems():
         if re.match(reg,node_name):
            for cls_name in cls.keys():
               h = members.get(cls_name,[])
               h.append(node_name)
               members[cls_name] = h
   members['all'] = all_hosts

   classes = dict()
   for node_name in all_hosts:
      node_classes = dict()
      for reg,cls in rules.iteritems():
         if re.match(reg,node_name):
            node_classes.update(cls)
      classes[node_name] = node_classes

   # Sort member lists for a more easy to read diff
   for cls in members.keys():
       members[cls].sort()

   return dict(classes=classes,members=members)

_db = None
def cosmos_db():
   global _db
   if _db is None:
      _db = _load_db()
   return _db

if __name__ == '__main__':
   print yaml.dump(cosmos_db())
