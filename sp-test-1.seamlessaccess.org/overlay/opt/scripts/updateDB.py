#!/usr/bin/env python3

import urllib.request, urllib.parse
import json
import sqlite3
import time, datetime

con = sqlite3.connect("/var/www/demoBeta/db/database.db")
cur = con.cursor()
cur.execute("CREATE TABLE IF NOT EXISTS registrationAuthority(id INTEGER PRIMARY KEY, date INTEGER, name TEXT UNIQUE);")
cur.execute("CREATE TABLE IF NOT EXISTS entity_category(id INTEGER PRIMARY KEY, date INTEGER, name TEXT UNIQUE);")
cur.execute("CREATE TABLE IF NOT EXISTS assurance_certification(id INTEGER PRIMARY KEY, date INTEGER, name TEXT UNIQUE);")
cur.execute("CREATE TABLE IF NOT EXISTS entity_category_support(id INTEGER PRIMARY KEY, date INTEGER, name TEXT UNIQUE);")
cur.execute("CREATE TABLE IF NOT EXISTS md_source (id INTEGER PRIMARY KEY, date INTEGER, name TEXT UNIQUE);")

print("Db create done")
timestamp = int(time.time())
print("Fetching data from https://a-1.thiss.io/metadata.json")
with urllib.request.urlopen("https://a-1.thiss.io/metadata.json") as url:
  print("Data fetched")
  data = json.load(url)

  registrationAuthority_list = {}
  md_source_list = {}
  assurance_certification_list = {}
  entity_category_list = {}
  entity_category_support_list = {}
  for entity in data:
    if 'type' in entity and entity['type'] == 'idp':
      registrationAuthority_list[entity['registrationAuthority']] = entity['registrationAuthority']
      for source in entity["md_source"]:
        md_source_list[source] = source
      if 'assurance_certification' in entity:
        for assurance_certification in entity['assurance_certification']:
          assurance_certification_list[assurance_certification] = assurance_certification
      if 'entity_category' in entity:
        for entity_category in entity['entity_category']:
          entity_category_list[entity_category] = entity_category
      if 'entity_category_support' in entity:
        for entity_category_support in entity['entity_category_support']:
          entity_category_support_list[entity_category_support] = entity_category_support

remove_ids = {}
# registrationAuthority
for row in cur.execute("SELECT id, name FROM registrationAuthority"):
  if row[1] in registrationAuthority_list:
    del(registrationAuthority_list[row[1]])
  else:
    remove_ids[row[0]] = row[1]

for id in remove_ids:
  print(f"Removing registrationAuthority {remove_ids[id]}")
  cur.execute(f"DELETE FROM registrationAuthority WHERE `id` = {id}")
  del(remove_ids[id])

for registrationAuthority in registrationAuthority_list:
  print(f"Adding registrationAuthority {registrationAuthority}")
  cur.execute(f"INSERT INTO registrationAuthority (`name`) VALUES ('{registrationAuthority}')")

# md_source
for row in cur.execute("SELECT id, name FROM md_source"):
  if row[1] in md_source_list:
    del(md_source_list[row[1]])
  else:
    remove_ids[row[0]] = row[1]

for id in remove_ids:
  print(f"Removing md_source {remove_ids[id]}")
  cur.execute(f"DELETE FROM md_source WHERE `id` = {id}")
  del(remove_ids[id])

for md_source in md_source_list:
  print(f"Adding md_source {md_source}")
  cur.execute(f"INSERT INTO md_source (`name`) VALUES ('{md_source}')")

# assurance_certification
for row in cur.execute("SELECT id, name FROM assurance_certification"):
  if row[1] in assurance_certification_list:
    del(assurance_certification_list[row[1]])
  else:
    remove_ids[row[0]] = row[1]

for id in remove_ids:
  print(f"Removing assurance_certification {remove_ids[id]}")
  cur.execute(f"DELETE FROM assurance_certification WHERE `id` = {id}")
  del(remove_ids[id])

for assurance_certification in assurance_certification_list:
  print(f"Adding assurance_certification {assurance_certification}")
  cur.execute(f"INSERT INTO assurance_certification (`name`) VALUES ('{assurance_certification}')")
con.commit()

# entity_category
for row in cur.execute("SELECT id, name FROM entity_category"):
  if row[1] in entity_category_list:
    del(entity_category_list[row[1]])
  else:
    remove_ids[row[0]] = row[1]

for id in remove_ids:
  print(f"Removing entity_category {remove_ids[id]}")
  cur.execute(f"DELETE FROM entity_category WHERE `id` = {id}")
  del(remove_ids[id])

for entity_category in entity_category_list:
  print(f"Adding entity_category {entity_category}")
  cur.execute(f"INSERT INTO entity_category (`name`) VALUES ('{entity_category}')")

# entity_category_support
for row in cur.execute("SELECT id, name FROM entity_category_support"):
  if row[1] in entity_category_support_list:
    del(entity_category_support_list[row[1]])
  else:
    remove_ids[row[0]] = row[1]

for id in remove_ids:
  print(f"Removing entity_category_support {remove_ids[id]}")
  cur.execute(f"DELETE FROM entity_category_support WHERE `id` = {id}")
  del(remove_ids[id])

for entity_category_support in entity_category_support_list:
  print(f"Adding entity_category_support {entity_category_support}")
  cur.execute(f"INSERT INTO entity_category_support (`name`) VALUES ('{entity_category_support}')")
con.commit()
