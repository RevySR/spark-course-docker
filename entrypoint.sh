#!/usr/bin/env bash

CMD=$1

case "$CMD" in
    "start" )
        chown -R mysql:mysql /var/lib/mysql /var/run/mysqld
        /etc/init.d/mysql start 
        /etc/init.d/ssh start
        start-dfs.sh && start-yarn.sh && start-hbase.sh
        nohup hiveserver2 > hive.log &
        ;;
esac

exec /bin/bash