FROM debian:12.5-slim

# Setup curl
RUN apt-get update
RUN apt-get install -y curl unzip cron

# Go to root (rquired for furhter scripts)
WORKDIR "/root"

# Setup clickhouse and s3 cli
COPY install-deps.sh /root/install-deps.sh
RUN chmod +x /root/install-deps.sh
RUN /root/install-deps.sh

# Setup the entry script
COPY setup.sh /root/setup.sh
RUN chmod +x /root/setup.sh

# Setup the backup script
COPY backup.sh /root/backup.sh
RUN chmod +x /root/backup.sh

# Setup cron job
RUN crontab -l | { cat; echo "55 23 * * * /root/backup.sh 2>&1 | tee -a /root/s3_backup.log"; } | crontab -

ENTRYPOINT ["sh", "-c", "/root/setup.sh"]