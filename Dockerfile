FROM alpine:3 as main

ARG ANSIBLE_VERSION

RUN set -eux; \
    apk --update add bash openssh-client ruby git python3 py3-pip openssl ca-certificates; \
    apk --update add --virtual \
      build-dependencies \
      build-base \
      python3-dev \
      libffi-dev \
      openssl-dev \
      musl-dev \
      cargo; \
    pip3 install --upgrade pip cffi --break-system-packages; \
    pip3 install "ansible==$ANSIBLE_VERSION" boto pywinrm --break-system-packages; \
    apk del build-dependencies; \
    rm -rf /var/cache/apk/*; \
# Remove PIP and Cargo cache
	rm -rf /root/.cargo /root/.cache; \
# Remove Python cache files
	find /usr/lib/ -name '__pycache__' -print0 | xargs -0 -n1 rm -rf; \
	find /usr/lib/ -name '*.pyc' -print0 | xargs -0 -n1 rm -rf; \
# Add hosts for convenience
    mkdir -p /etc/ansible; \
    echo -e "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

COPY assets/ /opt/resource/

FROM main as testing

RUN set -eux; \
    gem install rspec; \
    wget -q -O - https://raw.githubusercontent.com/troykinsella/mockleton/master/install.sh | bash; \
    cp /usr/local/bin/mockleton /usr/local/bin/ansible-galaxy; \
    cp /usr/local/bin/mockleton /usr/local/bin/ansible-playbook; \
    cp /usr/local/bin/mockleton /usr/bin/ssh-add;

COPY . /resource/

WORKDIR /resource
RUN rspec

FROM alpine:3 as print_latest_ansible_version

RUN apk --update add --no-cache py3-pip

COPY print_latest_ansible_version.sh /tools/
WORKDIR /tools
CMD ["./print_latest_ansible_version.sh"]

FROM main
