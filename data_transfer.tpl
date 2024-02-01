-- Copy data for the 'devices' table
INSERT INTO devices SELECT * FROM remoteSecure('${host}:9440', 'default.devices', 'default', '${password}');

-- Copy data for the 'app_versions_meta' table
INSERT INTO app_versions_meta SELECT * FROM remoteSecure('${host}:9440', 'default.app_versions_meta', 'default', '${password}');

-- Copy data for the 'devices_u' table
INSERT INTO devices_u SELECT * FROM remoteSecure('${host}:9440', 'default.devices_u', 'default', '${password}');

-- Copy data for the 'logs' table
INSERT INTO logs SELECT * FROM remoteSecure('${host}:9440', 'default.logs', 'default', '${password}');

-- Copy data for the 'logs_daily' table
INSERT INTO logs_daily SELECT * FROM remoteSecure('${host}:9440', 'default.logs_daily', 'default', '${password}');

-- Copy data for the 'app_storage_daily' table
INSERT INTO app_storage_daily SELECT * FROM remoteSecure('${host}:9440', 'default.app_storage_daily', 'default', '${password}');

-- Copy data for the 'mau' table
INSERT INTO mau SELECT * FROM remoteSecure('${host}:9440', 'default.mau', 'default', '${password}');

-- Note: Materialized views do not store data themselves and are populated based on the data in the tables they reference.
-- Therefore, you do not need to copy data for materialized views ('devices_u_mv', 'logs_daily_mv', 'app_storage_daily_mv', 'mau_mv').
-- They will be populated automatically once the data is inserted into the corresponding tables.

-- data_transfer.tpl
-- Copy data for the 'devices' table
