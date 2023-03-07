#!/bin/bash

/usr/sbin/resize2fs $(df -P . | sed -n '$s/[[:blank:]].*//p')