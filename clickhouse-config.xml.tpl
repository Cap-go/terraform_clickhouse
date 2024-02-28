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
