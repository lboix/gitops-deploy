#!/bin/bash

mkdir /root/.ssh
echo "${GIT_REPO_USER_RSA}" > /root/.ssh/id_rsa
chmod 400 /root/.ssh/id_rsa
# TODO : this line does assume this Git repo is on gitlab.com, so adapt accordingly
echo -e "Host gitlab.com\n\tStrictHostKeyChecking no" > /root/.ssh/config
