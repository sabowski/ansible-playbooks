# -*- mode: ruby -*-
# vi: set ft=ruby :

root_ca = File.read("test_certs/rootCA.crt")
domain = ".local.test"
gitlab_port = 8443
bridge_device = ENV["VAGRANT_BRIDGE_DEVICE"] || "br0"
k8s_use_bridge = ENV["VAGRANT_K8S_USE_BRIDGE"] || "true"

Vagrant.configure("2") do |config|

  # vbguest updates
  config.vbguest.auto_update = false

  ##############
  ### GITLAB ###
  ##############

  config.vm.define "gitlab" do |gitlab|

    # if you set a password using SMTP_PASSWORD env var email will be enabled
    enable_email = if ENV['SMTP_PASSWORD'].nil? then false else true end

    gitlab.vm.box = "debian/bookworm64"
    gitlab.vm.hostname = "gitlab" + domain
    gitlab.vm.network "forwarded_port", guest: 8443, host: 8443, host_ip: "127.0.0.1" # host_ip: 127.0.0.1 disables public access

    $post_message = <<EOF
Gitlab should now be up at https://gitlab#{domain}:#{gitlab_port}
EOF

    gitlab.vm.post_up_message = $post_message

    gitlab.vm.provider "virtualbox" do |vb|
      vb.memory = "16384"
      vb.cpus = 4
    end

    gitlab.vm.provision "ansible", type: 'ansible' do |ansible|
      ansible.playbook = "gitlab.yml"
      ansible.compatibility_mode = "2.0"
      ansible.galaxy_role_file = "requirements.yml"
      ansible.galaxy_roles_path = "galaxy-roles"
      ansible.extra_vars = {
        root_pw: "$y$j9T$i.GJ2PIbPS43zdQAaBRdZ.$MlTX4XOruJNLNkJZZbEXkz9YhImk2FK8Ju45JflbQiD", # toor
        root_ca: root_ca,
        gitlab_url: "gitlab" + domain,
        gitlab_port: gitlab_port,
        gitlab_ssl_cert: File.read("test_certs/gitlab.local.test.crt"),
        gitlab_ssl_key: File.read("test_certs/gitlab.local.test.key"),
        enable_email: enable_email
      }
      ansible.skip_tags = "vagrant_skip"
      # ansible.verbose = "-vvv"
    end
  end

  ##################
  ### KUBERNETES ###
  ##################

  k8s_vms = {
    'k8s-node01': '192.168.80.11',
    'k8s-node02': '192.168.80.12',
    # if more worker nodes desired, add them here. k8s-master must remain last
    # for provisioning to work correctly. Be sure to also update:
    #   * config.group.groups
    #   * ansible.limit
    #   * ansible.groups
    # Note that the ips here are only used if the vms are using
    # "private_network", default is to use "public_network"
    'k8s-master': '192.168.80.10'
  }

  config.group.groups = {
    "k8s" => [
      "k8s-node01",
      "k8s-node02",
      "k8s-master",
    ]
  }

  k8s_vms.each do |hostname, ip|
    config.vm.define hostname do |k8s|

      k8s.vm.box = "debian/bookworm64"
      k8s.vm.hostname = hostname.to_s + domain

      # Exposing services via metallb does not work unless we are bridged to
      # the host network. Not sure if this can be fixed using a different
      # configuration. Default here is to use bridge device.
      if k8s_use_bridge == "true"
        k8s.vm.network :public_network,
          :dev => bridge_device,
          :mode => "bridge",
          :type => "bridge"
      elsif k8s_use_bridge == "false"
        k8s.vm.network "private_network", ip: ip
      else
        puts "VAGRANT_K8S_USE_BRIDGE must be set to 'true' or 'false'"
        abort
      end

      k8s.vm.provider :libvirt do |libvirt|
        # minimum requirements to create cluster with kubeadm
        libvirt.cpus = 2
        libvirt.memory = 2000
      end

      k8s.vm.post_up_message = "To reprovision cluster run `vagrant provision k8s-master`"

      if hostname.to_s == "k8s-master"
        k8s.vm.provision "ansible" do |ansible|
          ansible.playbook = "kubernetes.yml"
          ansible.extra_vars = {
            is_vagrant: true,
            common_root_ca: root_ca
          }
          ansible.skip_tags = "vagrant_skip"
          ansible.compatibility_mode = "2.0"
          ansible.limit = ["k8s-master","k8s-node01","k8s-node02"]
          ansible.groups = {
            "kubernetes_node" => ["k8s-node01","k8s-node02"],
            "kubernetes_master" => ["k8s-master"]
          }
          # ansible.verbose = "-vvv"
        end
      end
    end
  end
end
