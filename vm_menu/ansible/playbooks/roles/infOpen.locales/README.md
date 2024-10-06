# locales

[![CI](https://github.com/infOpen/ansible-role-locales/workflows/CI/badge.svg)](https://github.com/infOpen/ansible-role-locales/actions)
[![Mergify Status][mergify-status]][mergify]
[![Updates](https://pyup.io/repos/github/infOpen/ansible-role-locales/shield.svg)](https://pyup.io/repos/github/infOpen/ansible-role-locales/)
[![Python 3](https://pyup.io/repos/github/infOpen/ansible-role-locales/python-3-shield.svg)](https://pyup.io/repos/github/infOpen/ansible-role-locales/)
[![Ansible Role](https://img.shields.io/ansible/role/17061.svg)](https://galaxy.ansible.com/infOpen/locales/)

Install locales package.

## Requirements

This role requires Ansible 2.8 or higher,
and platform requirements are listed in the metadata file.

## Testing

This role use [Molecule](https://github.com/ansible-community/molecule) to run tests.

Local and Github Actions tests run tests on Docker by default.
See molecule documentation to use other backend.

Currently, tests are done on:
- CentOS 7
- CentOS 8
- Debian Buster
- Debian Stretch
- Ubuntu Bionic
- Ubuntu Focal

and use:
- Ansible 2.8.x
- Ansible 2.9.x

### Running tests

#### Using Docker driver

```
$ tox
```

You can also configure molecule options and molecule command using environment variables:
* `MOLECULE_OPTIONS` Default: "--debug"
* `MOLECULE_COMMAND` Default: "test"

```
$ MOLECULE_OPTIONS='' MOLECULE_COMMAND=converge tox
```

## Role Variables

### Default role variables

``` yaml
# Packages management
locales_packages: "{{ _locales_packages }}"
locales_language_packs_packages: "{{ _locales_language_packs_packages | default([]) }}"
locales_repositories_cache_valid_time: 3600

# Files management
locales_config_file_dest: "{{ _locales_config_file_dest }}"
locales_gen_file_dest: "{{ _locales_gen_file_dest }}"
locales_update_command: "{{ _locales_update_command }}"
locales_config_file_owner: 'root'
locales_config_file_group: 'root'
locales_config_file_mode: '0644'

# Locales management
locales_to_configure:
  - name: 'en_US.UTF-8'
    modifier: 'UTF-8'
locales_defaults:
  LANG: 'en_US.UTF-8'
  LANGUAGE: 'en_US.UTF-8'
  LC_CTYPE: '"en_US.UTF-8"'
  LC_NUMERIC: '"en_US.UTF-8"'
  LC_TIME: '"en_US.UTF-8"'
  LC_COLLATE: '"en_US.UTF-8"'
  LC_MONETARY: '"en_US.UTF-8"'
  LC_MESSAGES: '"en_US.UTF-8"'
  LC_PAPER: '"en_US.UTF-8"'
  LC_NAME: '"en_US.UTF-8"'
  LC_ADDRESS: '"en_US.UTF-8"'
  LC_TELEPHONE: '"en_US.UTF-8"'
  LC_MEASUREMENT: '"en_US.UTF-8"'
  LC_IDENTIFICATION: '"en_US.UTF-8"'
  LC_ALL: 'en_US.UTF-8'
```

### Debian family role variables

``` yaml
# Packages
_locales_packages:
  - name: 'locales'

# Configuration files path
_locales_config_file_dest: '/etc/default/locale'
_locales_gen_file_dest: '/etc/locale.gen'

# Locale update command
_locales_update_command: '/usr/sbin/update-locale'
```

### Ubuntu OS role variables

``` yaml
locales_language_packs_packages:
  - name: 'language-pack-en'
```

## Dependencies

None

## Example Playbook

``` yaml
- hosts: servers
  roles:
    - { role: infOpen.locales }
```

## License

MIT

## Author Information

Alexandre Chaussier (for Infopen company)
- https://www.infopen.pro
- a.chaussier [at] infopen.pro

[mergify]: https://mergify.io
[mergify-status]: https://img.shields.io/endpoint.svg?url=https://gh.mergify.io/badges/infOpen/ansible-role-locales&style=flat
