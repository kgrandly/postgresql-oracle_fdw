#!/usr/bin/env bash

echo -e "\n# - pg_cron\n\nshared_preload_libraries = 'pg_cron'\ncron.database_name = 'postgres'" >> /var/lib/postgresql/data/postgresql.conf
