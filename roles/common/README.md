Common
=========

Shared configuration for all SaboNet nodes.

Requirements
------------

Role Variables
--------------

in "vars":
* optional:
    * common_root_pw: Root password used on all SaboNet hosts (default in bitwarden vault)

in "defaults":
* required:
    * common_root_ca: The root certificate for your home network (the actual contents of the cert, not filepath!)
* optional:
    * common_users: A list of users to install on all SaboNet hosts, each entry containing the following fields:
        - name: Users full name.
          username: Name of user account.
          password: Password hash for the account. Can be generated with the command `mkpasswd --method=yescrypt`.
          group: Name of the users group (typically the same as the username)
          groups: A list of additional groups to make this user a member of.
          gid: Group id number to use
          uid: User id number to use

Dependencies
------------

Example Playbook
----------------

    - hosts: all
      vars:
        root_ca: |
          -----BEGIN CERTIFICATE-----
          (certificate contents here...)
          -----END CERTIFICATE-----

      roles:
         - common

License
-------

BSD

Author Information
------------------

Erik Sabowski (airyk@sabowski.com)
