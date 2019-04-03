#!/usr/bin/expect -f
set timeout -1
spawn /splunkforwarder/bin/splunk start --accept-license
expect "Please enter an administrator username: "
send -- "admin\r"
expect "Please enter a new password: "
send -- "changeme\r"
expect "Please confirm new password: "
send -- "changeme\r"
expect eof
