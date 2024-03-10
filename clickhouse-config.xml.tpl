<clickhouse>
    <openSSL>
        <server>
            <certificateFile>${certificate_file}</certificateFile>
            <privateKeyFile>${private_key_file}</privateKeyFile>
        </server>
    </openSSL>
    <tcp_port_secure>9440</tcp_port_secure>
    <prometheus>
        <endpoint>/metrics</endpoint>
        <port>9363</port>
        <metrics>true</metrics>
        <events>true</events>
        <asynchronous_metrics>true</asynchronous_metrics>
        <errors>true</errors>
    </prometheus>


    <storage_configuration>
        <disks>
            <s3_plain>
                <type>s3_plain</type>
                <endpoint>${backup_s3_url_with_folder}</endpoint>
                <access_key_id>${backup_s3_access_key}</access_key_id>
                <secret_access_key>${backup_s3_secret_access_key}</secret_access_key>
            </s3_plain>
        </disks>
        <policies>
            <s3>
                <volumes>
                    <main>
                        <disk>s3_plain</disk>
                    </main>
                </volumes>
            </s3>
        </policies>
    </storage_configuration>

    <backups>
        <allowed_disk>s3_plain</allowed_disk>
    </backups>

</clickhouse>
