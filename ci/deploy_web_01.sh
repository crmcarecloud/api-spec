#!/bin/bash

set -xe

mkdir /mnt/remote-server;
sshfs -o allow_other developers@web-01.intr.cortex.cz:/var/www/web/developers.crmcarecloud.com/www /mnt/remote-server;
cd /mnt/remote-server;

export https_proxy=http://proxy.intr.cortex.cz:3128;
export http_proxy=http://proxy.intr.cortex.cz:3128;

#Update git
if [ ! -d ".git" ]; then
    git init;
    git remote add origin git@gitlab.gts.cortex.cz:carecloud/api-spec.git;
    git pull origin $CI_COMMIT_REF_NAME;
    git branch -m master $CI_COMMIT_REF_NAME;
else
    git checkout $CI_COMMIT_REF_NAME;
    git fetch origin $CI_COMMIT_REF_NAME;
    if [ 0 -eq $(git branch $(git rev-parse --abbrev-ref HEAD) --contains $CI_COMMIT_SHA > /dev/null 2> /dev/null; echo $?) ]; then
        git reset --hard $CI_COMMIT_SHA;
    else
        git reset --hard FETCH_HEAD;
    fi
    git clean -df;
fi

fusermount -zu /mnt/remote-server;