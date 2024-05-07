#!/usr/bin/env python3
#
# Puppet 'External Node Classifier' to tell puppet what classes to apply to this node.
#
# Docs: https://puppet.com/docs/puppet/5.3/nodes_external.html
#

import os
import re
import sys

import yaml

rules_path = os.environ.get("COSMOS_RULES_PATH", "/etc/puppet")

node_name = sys.argv[1]

rules = dict()
for p in rules_path.split(":"):
    rules_file = os.path.join(p, "cosmos-rules.yaml")
    if os.path.exists(rules_file):
        with open(rules_file) as fd:
            rules.update(yaml.safe_load(fd))

found = False
classes = dict()
for reg, cls in rules.items():
    if re.search(reg, node_name):
        if cls:
            classes.update(cls)
        found = True

if not found:
   sys.stderr.write(f"{sys.argv[0]}: {node_name} not found in cosmos-rules.yaml\n")

print("---\n" + yaml.dump(dict(classes=classes)))

sys.exit(0)
