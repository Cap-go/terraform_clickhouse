check_clickhouse_ready() {
    # Replace localhost with the actual host if needed
    curl -s "http://clickhouse-master:8123/ping" | grep -q "Ok."
    return $?
}

echo "Waiting for ClickHouse to be ready..."
while ! check_clickhouse_ready; do
    echo "ClickHouse is not ready yet. Retrying in 1 seconds..."
    sleep 1
done

echo "ClickHouse is ready."

BASE_COUNT=$(/root/clickhouse client --host clickhouse-master --password $CLICKHOUSE_PASSWORD -q "select count(*) from system.backup_log where name='Disk(\'s3_plain\', \'cloud_backup\')' AND status = 'BACKUP_CREATED'")

echo "Base backup count: $BASE_COUNT"

# Default value = 0
ERR_FREE_BASE_COUNT="${BASE_COUNT:-0}"
if [ "$ERR_FREE_BASE_COUNT" -gt 0 ]; then
    echo 'skipping making base backup ;-)'
else
    echo "creating the base backup"
    /root/clickhouse client --receive_timeout 900 -q "BACKUP DATABASE default TO Disk('s3_plain', 'cloud_backup')" --host clickhouse-master --password $CLICKHOUSE_PASSWORD
fi

# Setup amazon CLI
echo 'Setup amazon CLI'
aws configure set aws_access_key_id $S3_BACKUP_ACCESS_KEY
aws configure set aws_secret_access_key $S3_BACKUP_SECRET_ACCESS_KEY
aws configure set default.region auto
aws configure set default.output json
echo 'Amazon CLI configured!'

# Setup cronitor
echo 'Setup cron'
/sbin/service cron start
echo 'Setup cronitor done'

while :
do
	sleep 900
done