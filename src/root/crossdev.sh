#!/bin/bash

mkdir -pv /var/db/repos/localrepo-crossdev/{profiles,metadata}
echo 'crossdev' > /var/db/repos/localrepo-crossdev/profiles/repo_name
echo 'masters = gentoo' > /var/db/repos/localrepo-crossdev/metadata/layout.conf
chown -R portage:portage /var/db/repos/localrepo-crossdev

mkdir -pv /etc/portage/repos.conf

echo "[crossdev]
location = /var/db/repos/localrepo-crossdev
priority = 10
masters = gentoo
auto-sync = no" > /etc/portage/repos.conf/crossdev.conf

# You absolutely NEED to edit this line according to your crossdev-environment
crossdev --b '~2.34' --g '~9.3.0' --k '~5.4' --l '~2.32' -t armv6j-unknown-linux-gnueabihf