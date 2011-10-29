# pass_crypt

## Introduction
pass\_crypt is a simple Ruby application that allows the secure storage and retrieval of usernames and passwords.  Usernames and passwords are stored in an SQLite database, encrypted using AES 256-bit encryption with a personal passphrase.  Passwords can be inserted and retrieved using the clipboard for convenience and security.

## Requirements
- clipboard (gem)

    gem install clipboard # may require sudo

- xclip & libsqlite3 (linux packages)

    sudo apt-get install xclip libsqlite3

- You also need a version of Ruby installed that includes the OpenSSL libraries.  Refer to http://www.ruby-lang.org for help in installing Ruby.

## Installation
This will soon become a *gem* with bundler support.  Until then...

Using Git, clone the repository:

    git clone git@github.com:jamesds/pass_crypt.git

## Usage
Simply run pass\_crypt with no parameters to be shown brief usage instructions.

The SQLite database containing the encrypted data is kept in '~/.pass\_crypt/crypt.db'.  It may be wise to make backups of this file.

## License

Use as you wish.  I'll get a formal license when I release this as a gem.
