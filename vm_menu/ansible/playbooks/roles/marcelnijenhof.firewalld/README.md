Role Name
=========

Uses firewalld on CentOS/Redhat 7 or Fedora 21/22 to configure the firewall zones and rules

Requirements
------------

The ansible module firewalld is used for the configuration.

Role Variables
--------------

There are three sets of variables:
 - marcelnijenhof_firewalld_zones
 - marcelnijenhof_firewalld_allow_services
 - marcelnijenhof_firewalld_allow_ports


Values for marcelnijenhof_firewalld_zones:

    marcelnijenhof_firewalld_zones:
      zone: [zone]
      source: <source IP/network>
      interface: [interface]
      permanent: [True|False] (default: True)
      state: [enabled|disabled] (default: enabled)
      immediate: [True|False] (default: True)


Values for marcelnijenhof_firewalld_allow_services:

    marcelnijenhof_firewalld_allow_services:
      service: <service name>
      zone: [zone]			(default: public)
      permanent: [True|False]	(default: True)
      state: [enabled|disabled]	(default: enabled)
      immediate: [True|False] (default: True)

Only service is required!

Values for marcelnijenhof_firewalld_allow_ports:

    marcelnijenhof_firewalld_allow_ports:
      port: <port/protocol>
      zone: [zone]			(default: public)
      permanent: [True|False]	(default: True)
      state: [enabled|disabled]	(default: enabled)
      immediate: [True|False] (default: True)


Example Playbook
----------------

    - hosts: servers
      vars:
        marcelnijenhof_firewalld_zones:
            - { zone: "trusted", source: "192.168.1.1/24", interface: "eth0", state: "enabled", permanent: true, immediate: true }
        marcelnijenhof_firewalld_allow_services:
          - { service: "http" }
          - { service: "telnet", zone: "dmz", permanent: True, state: "disabled" }
      roles:
        - mvarian.firewalld

Disable firewalld service example
---------------------------------

    - hosts: servers
      vars:
        marcelnijenhof_firewalld_allow_services:
          - { marcelnijenhof_firewalld_disable: true }
      roles:
        - mvarian.firewalld



License
-------

BSD

Author Information
------------------

Written by Marcel Nijenhof (marceln@pion.xs4all.nl).
