DIST	:= "ubuntu:latest"

cosmos:
	fab all cosmos

upgrade:
	fab upgrade

tag:
	./bump-tag

test_in_docker:
	docker run --rm -it \
		-v ${CURDIR}:/multiverse:ro \
		\
		$(DIST) /multiverse/scripts/test-in-docker.sh
