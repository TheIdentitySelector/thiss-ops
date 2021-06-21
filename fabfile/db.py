import os
import sys
import yaml
import re

# disallow python2 as the output will not be correct
if sys.version_info.major != 3:
    sys.stderr.write('python2 no longer supported\n')
    sys.exit(1)


def _all_hosts():
    return list(filter(lambda fn: '.' in fn and not fn.startswith('.') and os.path.isdir(fn), os.listdir(".")))


def _load_db():
    rules_file = "cosmos-rules.yaml"
    if not os.path.exists(rules_file):
        sys.stderr.write('%s not found'.format(rules_file))
        sys.exit(1)

    with open(rules_file) as fd:
        rules = yaml.load(fd, Loader=yaml.SafeLoader)

    all_hosts = _all_hosts()

    members = dict()
    for node_name in all_hosts:
        for reg, cls in rules.items():
            if re.match(reg, node_name):
                for cls_name in cls.keys():
                    h = members.get(cls_name, [])
                    h.append(node_name)
                    members[cls_name] = h
    members['all'] = all_hosts

    classes = dict()
    for node_name in all_hosts:
        node_classes = dict()
        for reg, cls in rules.items():
            if re.match(reg, node_name):
                node_classes.update(cls)
        classes[node_name] = node_classes

    # Sort member lists for a more easy to read diff
    for cls in members.keys():
        members[cls].sort()

    return dict(classes=classes, members=members)


_db = None


def cosmos_db():
    global _db
    if _db is None:
        _db = _load_db()
    return _db


if __name__ == '__main__':
    print(yaml.dump(cosmos_db(), default_flow_style=None))
