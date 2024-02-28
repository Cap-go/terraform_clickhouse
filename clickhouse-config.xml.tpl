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

    <!-- Memory and Performance settings -->
    <max_server_memory_usage>26843545600</max_server_memory_usage> <!-- 25GB out of 32GB to leave room for OS and other processes -->
    <mark_cache_size>5368709120</mark_cache_size> <!-- 5GB for mark cache -->
    <max_bytes_before_external_group_by>10737418240</max_bytes_before_external_group_by> <!-- 10GB before using external memory for GROUP BY -->
    <max_bytes_before_external_sort>10737418240</max_bytes_before_external_sort> <!-- 10GB before using external memory for sorting -->
    <max_query_size>26214400</max_query_size> <!-- 25MB max query size -->
    <max_threads>16</max_threads> <!-- Utilize up to 16 threads for query execution -->
    
    <!-- MergeTree settings -->
    <merge_tree>
        <parts_to_throw_insert>300</parts_to_throw_insert>
        <parts_to_delay_insert>150</parts_to_delay_insert>
        <!-- Add other MergeTree specific settings here if needed -->
    </merge_tree>
</clickhouse>
