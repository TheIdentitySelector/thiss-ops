DIST	:= "ubuntu:latest"

cosmos:
	fab all cosmos

upgrade:
	fab upgrade

db: global/overlay/etc/puppet/cosmos-db.yaml

global/overlay/etc/puppet/cosmos-db.yaml: global/overlay/etc/puppet/cosmos-rules.yaml
	@python ./fabfile/db.py > global/overlay/etc/puppet/cosmos-db.yaml
	@git add global/overlay/etc/puppet/cosmos-db.yaml && git commit -m "update db" global/overlay/etc/puppet/cosmos-db.yaml

tag: db
	./bump-tag

test_in_docker:
	docker run --rm -it \
		-v ${CURDIR}:/multiverse:ro \
		\
		$(DIST) /multiverse/scripts/test-in-docker.sh
