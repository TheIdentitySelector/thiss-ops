#!/usr/bin/env python3

import sys
import yaml
import os
import re

node_name = sys.argv[1]

db_file = os.environ.get("COSMOS_ENC_DB","/etc/puppet/cosmos-db.yaml")
db = dict(classes=dict())

if os.path.exists(db_file):
   with open(db_file) as fd:
      db.update(yaml.load(fd))

print(yaml.dump(dict(classes=db['classes'].get(node_name,dict()),parameters=dict(roles=db.get('members',[])))))

