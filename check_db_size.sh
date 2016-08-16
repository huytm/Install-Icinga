#!/bin/bash
#huytm
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
_database="$1"
_warning="$2"
_critical="$3"

_size=`mysql -uroot -e "SELECT table_schema 'Database Name', SUM( data_length + index_length)/1024/1024 'Database Size (MB)' FROM information_schema.TABLES where table_schema = '$_database';" | awk '{print $2}' | grep -v "Name"`
_result=`echo $_size | awk -F '.' '{print $1}'`

if [ $_result -lt $_warning ]
then
        echo "The database $_database is normal | ok; ok; ok";
        exit ${STATE_OK};
elif [ $_result -ge $_warning ] && [ $_result -lt $_critical ];then
        echo "The database $_database is warning $_size MB";
        exit ${STATE_WARNING};
elif [ $_result -gt $_critical ]; then
    echo "The database $_database is critical $_size MB";
    exit ${STATE_CRITICAL};
fi
