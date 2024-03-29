#!/bin/bash
set -e
set -o pipefail
set -o xtrace

# setup lua
luarocks --local --lua-version=5.1 build --only-deps
eval $(luarocks --lua-version=5.1 path)

# prepare secrets
rm -r secret
cp -r secret_example secret
echo "config 'test', -> logging false" >> config.moon

# build
npm install --unsafe-perm=true
tup init && tup generate build.sh && ./build.sh
cat $(which busted) | sed 's/\/usr\/bin\/lua5\.1/\/usr\/local\/openresty\/luajit\/bin\/luajit/' > busted
chmod +x busted

# start postgres
echo "fsync = off" >> /var/lib/postgres/data/postgresql.conf
echo "synchronous_commit = off" >> /var/lib/postgres/data/postgresql.conf
echo "full_page_writes = off" >> /var/lib/postgres/data/postgresql.conf
su postgres -c '/usr/bin/pg_ctl -s -D /var/lib/postgres/data start -w -t 120'

make init_schema
make migrate
make test_db

moon cmd/refresh_events.moon

./busted -o utfTerminal
