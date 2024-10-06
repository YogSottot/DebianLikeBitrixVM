"""
Role tests
"""

import os
import pytest

from testinfra.utils.ansible_runner import AnsibleRunner

testinfra_hosts = AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


@pytest.mark.parametrize('name,distribution', [
    ('glibc-common', 'centos'),
    ('locales', 'debian'),
    ('locales', 'ubuntu'),
    ('language-pack-en', 'ubuntu'),
])
def test_packages(host, name, distribution):
    """
    Check if packages are installed
    """

    if distribution != host.system_info.distribution:
        pytest.skip('Test defined for another distribution')

    assert host.package(name).is_installed
