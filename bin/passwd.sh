#!/bin/sh

# docker-glftpd::passwd

if [ -n "$1" ]; then
  echo
  if command -v htpasswd >/dev/null 2>&1; then
    echo "htpasswd user shit:" 
    echo "$1" | htpasswd -n -i shit
  else
    echo "htpasswd not found, skipping"
  fi
  if command -v php >/dev/null 2>&1; then
    echo "php password_hash filemanager:" 
    php -r "print(password_hash(\"$1\", PASSWORD_DEFAULT));"
  else
    echo "php not found, skipping"
  fi
  if [ -x ./hashgen ]; then
    echo; echo
    echo "hashgen user glftpd:"
    ./hashgen glftpd "$1"
  else
    echo "hashgen not found, skipping"
  fi
  echo
else
  echo "USAGE: ./passwd.sh <password>"
fi
