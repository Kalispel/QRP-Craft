#!/bin/bash

# Print some information for Debugging and visibility
pwd 
echo '-------------------------------------------------------------'
printenv
echo '-------------------------------------------------------------'
echo 'Directory List (docroot)'
ls -la 
echo '-------------------------------------------------------------'
echo '\n'
echo '-------------------------------------------------------------'
echo 'Directory List (/etc)'
ls -la /etc
echo '-------------------------------------------------------------'
echo '\n'
echo '-------------------------------------------------------------'
echo 'Directory List (/dev)'
ls -la /dev
echo '-------------------------------------------------------------'
echo '\n'

echo 'Bash/Dash Shell Check:'
readlink -f $(which sh)
echo '\n'

echo 'PHP Version Check:'
php -v
echo '\n'

# Copy over environment variables so that they are visible in the Azure Kudu SSH terminal
(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/') | sudo tee -a /etc/profile

echo "\nYou are logged in as: `whoami`\n"

echo "\nInstallation check and update\n"

php craft install/check
php craft migrate/all
php craft update all --backup 0 --migrate
php craft pc/apply

# Start the SSHD service as root and supervisor as www-data
sudo /usr/sbin/sshd &
sudo /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisor.conf

