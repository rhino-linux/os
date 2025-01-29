#!/bin/bash

loc=$(df -P . | sed -n '$s/[[:blank:]].*//p')

/usr/bin/expect <<EOF
spawn /usr/sbin/parted ${loc%%p*} resizepart ${loc##*p} 100%
expect "Yes/No?"
send "Yes\r"
expect eof
EOF

/usr/sbin/resize2fs ${loc}
