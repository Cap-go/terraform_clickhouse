echo "Current date: $(date)"
OUTPUT=$(/root/clickhouse client --receive_timeout 900 -q "BACKUP DATABASE default TO Disk('s3_plain', 'incremental_$(date -u +%Y-%m-%d)') SETTINGS base_backup =  Disk('s3_plain', 'cloud_backup')" --host clickhouse-master --password $CLICKHOUSE_PASSWORD)

echo "Backup output\n$OUTPUT"

stringContain() { case $2 in *$1* ) return 0;; *) return 1;; esac ;}

if stringContain "BACKUP_CREATED" "$OUTPUT"; then
    echo 'Backup sucessful, deleting yesterday backup ;-)'
    today=$(date +%Y-%m-%d)
    yesterday="$(date -d "$today - 2 days" +%Y-%m-%d)"
    aws s3 rm "s3://$S3_BACKUP_BUCKET/backups/incremental_$yesterday/" --recursive --endpoint-url $S3_BACKUP_AWS_ENDPOINT
    echo "----------------"
else
    echo "backup failed!!!"
    echo "----------------"
    exit 1
fi