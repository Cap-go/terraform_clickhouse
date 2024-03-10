# Install clickhouse
curl https://clickhouse.com/ | sh
chmod +x /root/clickhouse

# Install AWS cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
chmod +x /root/aws/install
/root/aws/install