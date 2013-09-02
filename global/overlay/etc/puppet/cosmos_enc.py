#!/usr/bin/env python

import sys
import yaml
import os
import re

rules_path = os.environ.get("COSMOS_RULES_PATH","/etc/puppet")

node_name = sys.argv[1]

rules = dict()
for p in rules_path.split(":"):
   rules_file = os.path.join(p,"cosmos-rules.yaml")
   if os.path.exists(rules_file):
      with open(rules_file) as fd:
         rules.update(yaml.load(fd))

classes = dict()
for reg,cls in rules.iteritems():
   if re.search(reg,node_name):
      classes.update(cls)

print yaml.dump(dict(classes=classes))
