<clickhouse>
    <listen_host>::</listen_host>
    <listen_host>0.0.0.0</listen_host>
    <listen_try>1</listen_try>
    <tcp_port>9000</tcp_port>
    <!-- SSL configuration for secure TCP interface -->
    <tcp_port_secure>9440</tcp_port_secure>
    <server>
        <certificateFile>${certificate_file}</certificateFile>
        <privateKeyFile>${private_key_file}</privateKeyFile>
    </server>
</clickhouse>
