#!/bin/bash
# Set current user in nss_wrapper
USER_ID=$(id -u)
GROUP_ID=$(id -g)

if [ "$(id -u)" != "0" ]; then
    echo "Setting user ${USER_ID}:${GROUP_ID} to /etc/passwd and /etc/group"
    echo "default:x:${USER_ID}:${GROUP_ID}:Default Application User:${HOME}:/sbin/nologin" >> /etc/passwd
    echo "${USER_ID}:x:${GROUP_ID}:" >> /etc/group
fi

$@