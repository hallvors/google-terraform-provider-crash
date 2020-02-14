# Slipway

Code for creating infrastructure and deploying apps to Google Cloud

This repository is based on Gruntwork's "Introduction to Terraform" article series, in particular this one:
https://blog.gruntwork.io/how-to-create-reusable-infrastructure-with-terraform-modules-25526d65f73d?gi=230cda2839d7

A project that wishes to use Slipway for deployment should do the following:

1. In the repo's root folder, `git clone git@github.com:minus/slipway.git`
1. Add `slipway` on a new line inside the project's `.gitignore` file
1. Make sure you have a Google cloud service account set up and a JSON-file with a key stored locally (and ignored by Git - do not check in). I prefer keeping it in `config/local-secrets` but it can be anywhere - path is specified in `vars.sh`. TODO: document required roles/permissions TODO: let's hard-code this file name since vars.sh is part of the repo..
1. Also create a GitHub [deploy key](https://developer.github.com/v3/guides/managing-deploy-keys/#deploy-keys) for the project:
    1. `cd config/local-secrets && ssh-keygen -t rsa -b 4096 -f github_key -C "your_email@example.com"` (change email address). Do not enter a pass phrase
    1. Paste contents of public key file in Github repository settings. Do not grant it write-access.
1. Create a directory named `infra` and add a script named `vars.sh` ([example](https://github.com/minus/slipway-test/blob/master/infra/vars.sh)).
1. The `infra` directory can also have other content, see below for details.
1. To set up infrastructure for staging and deploy code, run this command from the repository's root folder: `slipway/init.sh staging`
1. To deploy some random branch to staging, run this command from the repository's root folder: `slipway/init.sh staging random-branch`
1. To deploy to production, run this command from the repository's root folder: `slipway/init.sh production master`

**Note:** to decrypt secrets first time you use Slipway to deploy a project, you'll need a decryption key from [Bitwarden](https://vault.bitwarden.com/#/vault). The Bitwarden entry is named *Slipway Ansible vault key*.

## Slipway expectations

Here's a complete list of everything Slipway expects from the application's repository and your local setup:

### Local setup - general config and stuff not checked in to Git

* Terraform, Ansible and the `gcloud` cli installed in locations on your PATH
* [SSH-authenticated access](https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account) to checking out things from private repos on GitHub
* Your public SSH key on `~/.ssh/id_rsa.pub` will be added to the virtual machine(s) so you can SSH into them
* The `gcloud` command line tool should have a valid session for a user who has access to the GCP project you are working on. (TODO: can we either drop this requirement or use the service account JSON file if we need gcloud for something?)

### Google cloud setup
* The project on Google Cloud must have sections like DNS and Compute enabled. AFAIK some sections may only be enabled once you have "visited" them on the G Cloud console site.
* The Google cloud storage bucket to save Terraform state must already exist. Create a bucket named `terraform-state-PROJECT-ENVIRONMENT`, for example `terraform-state-slipway-staging`.

### In the repository

#### Checked in
* The project must have an `./infra/vars.sh` file defining a number of constants:
  * `GOOGLE_AUTH_FILE` - path to the Google Cloud credentials file in `local-secrets`.  TODO: this is here because we have not decided a specific name. Maybe just dictate $PROJECT_NAME-google-cloud-access.json or something?
  * `GOOGLE_PROJECT` - the GCP project resources should be created in. Separate apps should likely live in separate projects.
  * `GOOGLE_REGION`, `GOOGLE_ZONE` - the geographic region and zone this app should be deployed in
* `infra/apt` contains files to install OS-level requirements such as nodejs.
  * `*.key` files GPG keys for repositories, they are automatically installed on host with Ansible
  * `*.list` files are expected to contain references to additional repositories, these are also automatically handled with Ansible
  * `apt-requirements.txt` is a plain text file listing packages to install with apt-get, one per line
* `infra/systemd` defines services that are expected to run, including config for things like auto-resume. Will be copied to `/etc/systemd/system` on every deploy. Files can also be Jinja 2 templates with a .j2 extension.
* `infra/nginx` defines Nginx setup. Will be copied to `/etc/systemd/system` on every deploy. Files can also be Jinja 2 templates (with or without a .j2 extension, sorry about the inconsistency).
* `infra/encrypted-secrets` can contain project-specific secrets that will be decrypted on first run and placed in `config/local-secrets`. The key for encrypting/decrypting secrets should be shared on Bitwarden (remember to make "Minus" the owner or use the Share feature so the key won't be private for your eyes only).
* `infra/config-templates` can define any number of Jinja 2 templates that will be transformed and placed in `config/`. Note that variables in `config/local-secrets/*.y[a]ml`-files will be available. [example template file](https://github.com/minus/slipway-test/blob/master/infra/config-templates/demo.json.j2). The corresponding local-secrets file is not in the slipway-testing repo (since it not being in the repo is the whole point) but it simply contains something like `example_secret: "exexexexamplish"`
* The project's `.gitignore` file should contain an entry `**/.terraform/` (although these files will likely be created in the `slipway` folder Git should already ignore..)
* `infra/ansible/roles/post_checkout/tasks/` should define Ansible tasks to run after pulling code from Github. This is a good place to add tasks like `yarn install` or build steps. [example file](https://github.com/minus/slipway-test/blob/master/infra/ansible/roles/post_checkout/tasks/main.yaml)
* `infra/cron` can contain JSON-files defining settings for CRON jobs (will be configured as ~Google Cloud Scheduler jobs~ curl actions in crontab to trigger HTTP requests). (We don't use Cloud Scheduler at the moment because it is not available in all regions and requires extra services set up.) [Example file](https://github.com/minus/slipway-test/blob/master/infra/cron/test_cron_job.json). Valid settings in this file are:
  * `url` (important: relative to **admin** host, so `"url": "/tools/test"` will resolve to https://admin.foo/tools/test)
  * `headers`, `body`, `method` - what you expect
  * `schedule`: CRON-style schedule string
  * `tokenfile`, `tokenname`: if you want a secret sent to your URL, define a YAML file containing the secret and set these properties. Set `tokenfile` to the path to the (decrypted) YAML file, relative to the project root directory, and `tokenname` to the name of the correct key in that YAML file. It's also a good idea to create a config file template that gets the same token included and make sure the server code defining the end point [verifies incoming requests](https://github.com/minus/slipway-test/blob/master/server.js#L19-L22) against that token. Note that the token will be sent in a HTTP header named `Token`. (Example config: slipway-test has a [cron job config file](https://github.com/minus/slipway-test/blob/master/infra/cron/test_cron_job.json) pointing to the expected location of the decrypted secrets.yml file, it also has a [site config file template](https://github.com/minus/slipway-test/blob/master/infra/config-templates/cron_token.json.j2) to make the same secret string available to the server code).

#### In project file system, but not on Github

* `./config/local-secrets` folder with
  * Google Cloud credentials file (this file can be shared out-of Github between project members or each can generate a new one).
  * `github_key.pub` and `github` files for Github deploy keys
  * Optionally `secrets.yaml` for variables that will be used in config file templates - passwords, tokens etc. All `.yml` or `.yaml` files here will be considered Ansible variable source files.


### App behaviour

* Nginx should serve content on port 8080 (probably proxy'ing some other app like Node)
* On `GET /gcp_healthcheck`, the app should respond with 200 OK

### Workflows

* Slipway scripts (in particular the Terraform config ones) should be used to manage **ALL** changes to the configuration of virtual machines, network settings etc. **No** changes should happen manually through the Google Cloud console or the gcloud command line tool.
