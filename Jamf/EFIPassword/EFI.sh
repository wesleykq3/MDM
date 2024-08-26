#!/bin/bash


firmware_password="1234"


if [  `uname -m ` !=  "arm64" ];then

/usr/bin/expect <<EOT

#!/usr/bin/expect
set timeout -1


set firmware_password "$firmware_password"

spawn sudo /usr/sbin/firmwarepasswd -setpasswd

expect "Enter new password:"
send "\$firmware_password\r"

expect "Re-enter new password:"
send "\$firmware_password\r"

expect eof
EOT

esle

exit 0

fi
