ANSIBLE_VERSION = 10.0.1

.PHONY: build
build:
	docker build --pull --target main -t concourse-ansible-playbook-resource \
		--build-arg ANSIBLE_VERSION="${ANSIBLE_VERSION}" \
		.

.PHONY: test
test:
	docker build --pull --target testing -t concourse-ansible-playbook-resource:testing \
		--build-arg ANSIBLE_VERSION="${ANSIBLE_VERSION}" \
		.

.PHONY: print_latest_ansible_version
print_latest_ansible_version:
	image=$$(docker build --pull -q --target print_latest_ansible_version .) \
	&& docker run --rm -it $$image \
	&& docker image rm $$image >/dev/null
