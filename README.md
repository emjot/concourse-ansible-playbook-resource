# Concourse Ansible Playbook Resource

A [Concourse CI](https://concourse-ci.org) resource for running Ansible playbooks.

[<img src="https://concourse.emjot.de/api/v1/teams/emjot/pipelines/ansible-resource/jobs/build-and-publish/badge">](https://concourse.emjot.de/teams/emjot/pipelines/ansible-resource)

Fork of https://github.com/troykinsella/concourse-ansible-playbook-resource/.
(Main reason for this fork is that we want to build it regularly to keep images and ansible versions up to date,
which does not seem to happen for the original repo as of mid 2024. We will make a best effort to stay up to date
with the original repo if there are any changes. Note that git version tags will differ.)

Images are published to https://hub.docker.com/r/emjotde/concourse-ansible-playbook-resource/.

The resource image contains the latest version of ansible, installed by pip,
as of when the image was created. It runs ansible with python 3.
See the `Dockerfile` for other supplied system and pip packages.

## Tags

A new image is published from master at least once a week (more often if there are new commits on master). There are four kinds of tags being published, three rolling and one static.

Rolling Tags:
- `latest`: points to the latest image pushed which contains the latest version of Ansible.
- `ansibleANSIBLE_VERSION` and `ansibleANSIBLE_MAJOR`: These two tags are based on the ansible version (e.g. `ansible10.0.1` and `ansible10`, respectively) and are republished weekly. Only the latest version of ansible is republished. Older versions will become stale.

Static Tag:
- `REPO_VERSION-ansibleANSIBLE_VERSION-YYYYmmdd`: This tag is a describe_ref string of the git repo commit plus the ansible version plus the date it was published. If you want to stay on a specific ansible/image version then sticking to a particular build will meet your needs.

## Source Configuration

Most source attributes map directly to `ansible-playbook` options. See the
`ansible-playbook --help` for further details.

The `git_*` attributes are relevant to referencing git repositories in the `requirements.yml` file
which are pulled from during `ansible-galaxy install`.

* `debug`: Optional. Boolean. Default `false`. Echo commands and other normally-hidden outputs useful for troubleshooting.
* `env`: Optional. A list of environment variables to apply.
  Useful for supplying task configuration dependencies like `AWS_ACCESS_KEY_ID`, for example, or specifying
  [ansible configuration](https://docs.ansible.com/ansible/latest/reference_appendices/config.html) options
  that are unsupported by this resource. Note: Unsupported ansible configurations can also be applied in `ansible.cfg`
  in the playbook source.
* `git_global_config`: Optional. A list of git global configurations to apply (with `git config --global`).
* `git_https_username`:  Optional. The username for git http/s access.
* `git_https_password`: Optional. The password for git http/s access.
* `git_private_key`: Optional. The git ssh private key.
* `git_skip_ssl_verification`: Optional. Boolean. Default `false`. Don't verify TLS certificates.
* `user`: Optional. Connect to the remote system with this user.
* `requirements`: Optional. Default `requirements.yml`. If this file is present in the
  playbook source directory, it is used with `ansible-galaxy --install` before running the playbook.
* `ssh_common_args`: Optional. Specify options to pass to `ssh`.
* `ssh_private_key`: Optional. The `ssh` private key with which to connect to the remote system.
* `vault_password`: Optional. The value of the `ansible-vault` password.
* `verbose`: Optional. Specify, `v`, `vv`, etc., to increase the verbosity of the
  `ansible-playbook` execution.

### Example

```yaml
resource_types:
- name: ansible-playbook
  type: docker-image
  source:
    repository: emjotde/concourse-ansible-playbook-resource
    tag: latest

resources:
- name: ansible
  type: ansible-playbook
  source:
    debug: false
    user: ubuntu
    ssh_private_key: ((ansible_ssh_private_key))
    vault_password: ((ansible_vault_password))
    verbose: v
```

## Behaviour

### `check`: No Op

### `in`: No Op

### `out`: Execute `ansible` Playbook

Execute `ansible-playbook` against a given playbook and inventory file,
firstly installing dependencies with `ansible-galaxy install -r requirements.yml` if necessary.

Prior to running `ansible-playbook`, if an `ansible.cfg` file is present in the
`path` directory, it is sanitized by removing entries for which the equivalent
command line options are managed by this resource. The result of this sanitization
can be seen by setting `source.debug: true`.

#### Parameters

Most parameters map directly to `ansible-playbook` options. See the
`ansible-playbook --help` for further details.

* `become`: Optional. Boolean. Default `false`. Run operations as `become` (privilege escalation).
* `become_user`: Optional. Run operations with this user.
* `become_method`: Optional. Privilege escalation method to use.
* `check`: Optional. Boolean. Default `false`. Don't make any changes;
  instead, try to predict some of the changes that may occur.
* `diff`: Optional. Boolean. Default `false`. When changing (small) files and
  templates, show the differences in those files; works great with `check: true`.
* `inventory`: Required. The path to the inventory file to use, relative
  to `path`.
* `limit`: Optional. Limit the playbook run to provided hosts/groups.
* `playbook`: Optional. Default `site.yml`. The path to the playbook file to run,
  relative to `path`.
* `skip_tags`: Optional. Only run plays and tasks not tagged with this list of values.
* `setup_commands`: Optional. A list of shell commands to run before executing the playbook.
  See the `Custom Setup Commands` section for explanation.
* `tags`: Optional. Only run plays and tasks tagged with this list of values.
* `vars`: Optional. An object of extra variables to pass to `ansible-playbook`.
  Mutually exclusive with `vars_file`.
* `vars_file`: Optional. A file containing a JSON object of extra variables
  to pass to `ansible-playbook`. Mutually exclusive with `vars`.
* `path`: Required. The path to the directory containing playbook sources. This typically
  will point to a resource pulled from source control.

#### Custom Setup Commands

As there are a myriad of Ansible modules, each of which having specific system dependencies,
it becomes untenable for all of them to be supported by this resource Docker image.
The `setup_commands` parameter of the `put` operation allows the pipeline manager to
install system packages known to be depended upon by the particular playbooks being executed.
Of course, this flexibility comes at the cost of having to execute the commands upon
every `put`. That said, this Concourse resource does intend to supply a set of dependencies out
of the box to support the most common or basic Ansible modules. Please open a ticket
requesting the addition of a system package if it can be rationalized that it will benefit
a wide variety of use cases.

#### Example

```yaml
# Extends example in Source Configuration

jobs:
- name: provision-frontend
  plan:
  - get: master # git resource
  - put: ansible
    params:
      check: true
      diff: true
      inventory: inventory/some-hosts.yml
      playbook: site.yml
      path: master
```

## Development

PRs are welcome!

```bash
# Testing:
make test
# edit Makefile to change the currently set ANSIBLE_VERSION or run e.g.: make test ANSIBLE_VERSION=10.0.1

# Building:
make build
# edit Makefile to change the currently set ANSIBLE_VERSION or run e.g.: make build ANSIBLE_VERSION=10.0.1

# For convenience, get currently latest ansible version available in pip:
make print_latest_ansible_version
```

## Releasing

Update `CHANGELOG.md`: Amend any changes that happened (if that didn't already happen in the PRs/commits)
and add new version header. Tag with new version and push.

## License

MIT © Troy Kinsella
