.PHONY: buld-% update-scripts validate-%

%:
	./scripts/create-1-click.sh $* $*-20-04

build-%:
	packer build $*/te{
  "variables": {
    "do_api_token": "{{env `DIGITALOCEAN_API_TOKEN`}}",
    "image_name": "docker-20-04-snapshot-{{timestamp}}",
    "apt_packages": "apt-transport-https ca-certificates curl jq linux-image-extra-virtual software-properties-common ",
    "application_name": "Docker",
    "application_version": "19.03.12",
    "docker_compose_version": "1.27.4"
  },
  "sensitive-variables": [
    "do_api_token"
  ],
  "builders": [
    {
      "type": "digitalocean",
      "api_token": "{{user `do_api_token`}}",
      "image": "ubuntu-20-04-x64",
      "region": "nyc3",
      "size": "s-1vcpu-1gb",
      "ssh_username": "root",
      "snapshot_name": "{{user `image_name`}}"
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "inline": [
        "cloud-init status --wait"
      ]
    },
    {
      "type": "file",
      "source": "common/files/var/",
      "destination": "/var/"
    },
    {
      "type": "file",
      "source": "docker-20-04/files/etc/",
      "destination": "/etc/"
    },
    {
      "type": "shell",
      "environment_vars": [
        "DEBIAN_FRONTEND=noninteractive",
        "LC_ALL=C",
        "LANG=en_US.UTF-8",
        "LC_CTYPE=en_US.UTF-8"
      ],
      "inline": [
        "apt -qqy update",
        "apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' full-upgrade",
        "apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install {{user `apt_packages`}}",
        "apt-get -qqy clean"
      ]
    },
    {
      "type": "shell",
      "environment_vars": [
        "application_name={{user `application_name`}}",
        "application_version={{user `application_version`}}",
        "docker_compose_version={{user `docker_compose_version`}}",
        "DEBIAN_FRONTEND=noninteractive",
        "LC_ALL=C",
        "LANG=en_US.UTF-8",
        "LC_CTYPE=en_US.UTF-8"
      ],
      "scripts": [
        "common/scripts/010-docker.sh",
        "common/scripts/011-docker-compose.sh",
        "common/scripts/012-grub-opts.sh",
        "common/scripts/013-docker-dns.sh",
        "common/scripts/014-ufw-docker.sh",
        "common/scripts/020-application-tag.sh",
        "common/scripts/900-cleanup.sh"
      ]
    }
  ]
}
mplate.json

validate-%:
	packer validate $*/template.json

update-scripts:
	curl -o common/scripts/999-img_check.sh https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/img_check.sh
	curl -o common/scripts/900-cleanup.sh https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/cleanup.sh
