Kubernetes
=========

Installs and configures a kubernetes cluster.

The work here was heavily borrowed from:
* https://www.linuxtechi.com/install-kubernetes-on-ubuntu-22-04/
* https://github.com/tjtharrison/kubernetes-deploy
    * https://tjtharrison.medium.com/installing-a-bare-metal-kubernetes-cluster-with-ansible-59d20bf77c4c

Requirements
------------

* Assumes a single master architecture. Multiple masters are not supported
* For running vagrant, the "vagrant-group" plugin is required
* `jmespath` (python package) must be installed. Recommended to create a virtual environment and run `pip install -r requirements.txt` (which was also install `jmespath``)

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

* kubernetes_version: The version of the kubernetes repo to install
* kubernetes_pod_network_cidr: The network to use for the pod network. Must not conflict with any existing ip space in your network.

Dependencies
------------

* common: role used to install shared settings.

Example Playbook
----------------

- name: Install and configure kubernetes
  hosts: all

  roles:
    - role: common
    - role: kubernetes

License
-------

BSD

Author Information
------------------

Erik Sabowski (airyk@sabowski.com)
