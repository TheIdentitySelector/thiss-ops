cosmos:
	fab all cosmos 

upgrade:
	fab upgrade

db:
	@python ./fabfile/db.py > global/overlay/etc/puppet/cosmos-db.yaml
	@git add global/overlay/etc/puppet/cosmos-db.yaml && git commit -m "update db" global/overlay/etc/puppet/cosmos-db.yaml

tag: db
	./bump-tag
