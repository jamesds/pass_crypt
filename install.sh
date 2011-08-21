#!/bin/sh
echo "Putting a symbolic link into /usr/bin. Run with 'pass_crypt'"
echo "\nProtip: put the following alias into your .bash_aliases file"
echo "alias pc='pass_crypt'"

ln -s $PWD/pass_crypt.rb /usr/bin/pass_crypt
