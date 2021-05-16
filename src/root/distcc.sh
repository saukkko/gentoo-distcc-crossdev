#!/bin/bash
rc-update add distccd default
mv /etc/conf.d/distccd /etc/conf.d/distccd_original
mv /etc/conf.d/distccd.conf /etc/conf.d/distccd

cp /etc/init.d/distccd /root/distccd-init.backup
cat /etc/init.d/distccd|sed 's/\(^.*need\snet$\)/#\1/' >> /etc/init.d/distccd