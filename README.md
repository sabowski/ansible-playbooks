# ansible

ansible code for home network

create password

```bash
# for debian bookworm
$ mkpasswd --method=yescrypt
```

## GitLab (gitlab.yml)

This is the only playbook meant to be run by hand, all others should be run in
CI/CD pipelines through GitLab

### Important vars

#### Defined in gitlab.yml

The variables should typically be updated in the source, rather than be
overridden from the command line.

| variable               | default                              | description                         |
|------------------------|--------------------------------------|-------------------------------------|
| `root_pw`              | unencrypted value in bitwarden vault | password hash for linux `root` user |
| `gitlab_install_value` | `16.3.2`                             | version of gitlab to install        |

#### Ansible variables (pass in as `--extra-vars`)

##### Required

| variable          | description                                                                 |
|-------------------|-----------------------------------------------------------------------------|
| `root_ca`         | root CA certificate                                                         |
| `gitlab_ssl_cert` | TLS certificate to use for gitlab UI                                        |
| `gitlab_ssl_key`  | TLS key to use for gitlab UI                                                |

##### Optional

| variable                             | default                | description                                                                 |
|--------------------------------------|------------------------|-----------------------------------------------------------------------------|
| `gitlab_port`                        | `443`                  | port to run GitLab UI                                                       |
| `gitlab_url`                         | ansible_hostname       | hostname that the gitlab installation will be availble at (assumes `https`) |
| `gitlab_rails_smtp_address`          | none                   | hostname of smtp server for sending email                                   |
| `gitlab_rails_smtp_user_name`        | `gitlab@local.test`  | username for smtp server login                                              |
| `gitlab_rails_smtp_domain`           | `local.test`         | email domain                                                                |
| `gitlab_rails_gitlab_email_from`     | `gitlab@local.test`  | email to use as `From:` in emails sent from GitLab                          |
| `gitlab_rails_gitlab_email_reply_to` | `noreply@local.test` | "reply to" email for emails sent from GitLab                                |

The following variables may need to be adjusted, depending on the mail host
being used. These values are known to work for Dreamhost SMTP accounts

| variable                                 | default | description |
|------------------------------------------|---------|-------------|
| `gitlab_rails_smtp_enable_starttls_auto` | false   |             |
| `gitlab_rails_smtp_tls`                  | true    |             |
| `gitlab_rails_smtp_openssl_verify_mode`  | 'peer'  |             |

#### Environment variables

##### Optional

In order to enable email, the environment variable `SMTP_PASSWORD` must be set to the password of the SMTP account being used to send email from GitLab

### Setting up environment to install gitlab

First install Debian Bookworm (12) using the preseed file. To provide access to the preseed file use the `http.server` python module to serve it over http:

```bash
cd preseeds
python -m http.server 9000
```

Then during the install use the following url to point to the preseed file (replacing `<HOSTNAME_OR_IP>` with the hostname or IP of the machine hosting the preseed file):

`http://<HOSTNAME_OR_IP>:9000/debian_bookworm.cfg`

You will also need to provide ansible with the root CA cert and the gitlab certificate/key. To do this create a file in the root of this repo called `extra-vars.yml` using the following template and update the values. Ensure that the entire key is indented correctly, and do not commit this file to source!
```
---
root_ca: |
  -----BEGIN CERTIFICATE-----
  ...
  ...
  -----END CERTIFICATE-----
gitlab_ssl_cert: |
  -----BEGIN CERTIFICATE-----
  ...
  ...
  -----END CERTIFICATE-----
gitlab_ssl_key: |
  -----BEGIN PRIVATE KEY-----
  ...
  ...
  -----END PRIVATE KEY-----
```

### Running ansible

If you haven't already copy your ssh key to your ssh account on the gitlab server otherwise ansible won't be able to connect.

If all the steps in the previous section have been done we can now run ansible:

`$ ansible-playbook -i inventory gitlab.yml --extra-vars @extra-vars.yml -K`

Don't walk away just yet! You will have to run it twice, as soon as the password of the account is updated sudo will fail, so just run it again with the updated sudo password.

### Next steps after gitlab installation

* confirm email works (if enabled). See "Testing email settings" below.
* update gitlab root account password. (initial password is in `/etc/gitlab/initial_root_password`)
* update gitlab root account email address
* add user account

### Vagrant testing

The included `Vagrantfile` can be used to test the github ansible playbook.
Adding linux users and groups is disabled in vagrant test to avoid issues with
uid/gid collision.

#### TLS certificates for testing

Before starting up the vagrant test instance you must ensure that test certificates are generated. 

```bash
$ cd test_certs/
$ ./gen_test_certs.sh gitlab
```

#### DNS

If you want to be able to access the vagrant test instance at [https://gitlab.local.test:8443](https://gitlab.local.test:8443) you must do one of the following:

* Set your local DNS (eg: pihole) to return `127.0.0.1` for the hostname `gitlab.local.test`
* Add `127.0.0.1 gitlab.local.test` to `/etc/hosts`

#### Testing email settings

* enter rails console

    ```bash
    $ sudo gitlab-rails console
    ```

* at `irb>` prompt run (replaces `<DEST_MAIL>` with the account to send the test email to):
    ```bash
    irb(main):001:0> Notify.test_email('<DEST_EMAIL>', 'GitLab email test', 'This is a test of GitLab email sending').deliver_now
    ```
