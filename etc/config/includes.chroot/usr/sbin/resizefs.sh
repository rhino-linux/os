#!/bin/bash

loc=$(df -P . | sed -n '$s/[[:blank:]].*//p')
dev=${loc%%p*}
part=${loc##*p}

/usr/bin/expect <<EOF
spawn /usr/sbin/parted ${dev} print
expect {
    "Fix/Ignore?" {
        send "Fix\r"
        exp_continue
    }
    eof
}

spawn /usr/sbin/parted ${dev} resizepart ${part} 100%
expect {
    "Yes/No?" {
        send "Yes\r"
        exp_continue
    }
    eof
}
EOF

/usr/sbin/resize2fs ${loc}
