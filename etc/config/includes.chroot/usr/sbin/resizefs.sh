#!/bin/bash

loc=$(df -P . | sed -n '$s/[[:blank:]].*//p')

/usr/sbin/parted -s ${loc%%p*} resizepart ${loc##*p} 100%
/usr/sbin/resize2fs ${loc}
