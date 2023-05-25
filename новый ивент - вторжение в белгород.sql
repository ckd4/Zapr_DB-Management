--DROP EVENT SESSION MySession
--ON SERVER

--go
--CREATE EVENT SESSION MySession
--    ON SERVER 
--    ADD EVENT sqlserver.error_reported
--    --(
--    --    WHERE ([package0].[counter] <= (4))
--    --),
--	,ADD EVENT sqlserver.rpc_completed
--    --(
--    --    WHERE ([package0].[counter] <= (4))
--    --)
--    ADD TARGET package0.event_file(SET filename=N'C:\КАК ХОЧУ\XEDBDeletedCreated.xel')
--    WITH
--    (
--        MAX_MEMORY = 4096 KB,
--        MAX_DISPATCH_LATENCY = 3 SECONDS
--    );


CREATE EVENT SESSION [XE session 01] ON SERVER 
ADD EVENT sqlserver.error_reported(
    ACTION(sqlserver.client_app_name,sqlserver.database_id,sqlserver.query_hash,sqlserver.session_id)
    WHERE ([package0].[divides_by_uint64]([sqlserver].[session_id],(5)) AND [package0].[greater_than_uint64]([sqlserver].[database_id],(4)) AND [package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.module_end(SET collect_statement=(1)
    ACTION(sqlserver.client_app_name,sqlserver.database_id,sqlserver.query_hash,sqlserver.session_id)
    WHERE ([package0].[divides_by_uint64]([sqlserver].[session_id],(5)) AND [package0].[greater_than_uint64]([sqlserver].[database_id],(4)) AND [package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.client_app_name,sqlserver.database_id,sqlserver.query_hash,sqlserver.session_id)
    WHERE ([package0].[divides_by_uint64]([sqlserver].[session_id],(5)) AND [package0].[greater_than_uint64]([sqlserver].[database_id],(4)) AND [package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.sp_statement_completed(SET collect_object_name=(1)
    ACTION(sqlserver.client_app_name,sqlserver.database_id,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id)
    WHERE ([package0].[divides_by_uint64]([sqlserver].[session_id],(5)) AND [package0].[greater_than_uint64]([sqlserver].[database_id],(4)) AND [package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.sql_batch_completed(SET collect_batch_text=(1)
    ACTION(sqlserver.client_app_name,sqlserver.database_id,sqlserver.query_hash,sqlserver.session_id)
    WHERE ([package0].[divides_by_uint64]([sqlserver].[session_id],(5)) AND [package0].[greater_than_uint64]([sqlserver].[database_id],(4)) AND [package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.sql_statement_completed(SET collect_statement=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'study_org')))
ADD TARGET package0.event_file(SET filename=N'C:\КАК ХОЧУ\nuhbeb.xel'),
ADD TARGET package0.ring_buffer
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=ON)
GO







	select * from sys.server_event_sessions

use master
SELECT * FROM sys.fn_xe_file_target_read_file('C:\КАК ХОЧУ\nuhbeb_0_133239478116000000.xel', NULL, NULL, NULL)

SELECT CAST(event_data AS XML) AS EventData
FROM sys.fn_xe_file_target_read_file('C:\КАК ХОЧУ\nuhbeb_0_133239478116000000.xel', NULL, NULL, NULL) SELECT CAST(event_data AS XML) AS EventData
FROM sys.fn_xe_file_target_read_file('C:\КАК ХОЧУ\nuhbeb_0_133239478116000000.xel', NULL, NULL, NULL)




SELECT
 event_xml.value('(./@name)', 'varchar(1000)') as event_name,
 --event_xml.value('(./data[@name="database_id"]/value)[1]', 'int') as database_id,
 --event_xml.value('(./data[@name="nt_username"]/value)[1]', 'sysname') as nt_username
 --event_xml.value('(./data[@name="collect_system_time"]/value)[1]', 'datetime2') as collect_system_time,
 --event_xml.value('(./data[@name="object_type"]/value)[1]', 'varchar(25)') as object_type,
 event_xml.value('(./data[@name="duration"]/value)[1]', 'bigint') as duration,
 --event_xml.value('(./data[@name="cpu"]/value)[1]', 'bigint') as cpu,
 --event_xml.value('(./data[@name="row_count"]/value)[1]', 'int') as row_count,
 --event_xml.value('(./data[@name="reads"]/value)[1]', 'bigint') as reads,
 --event_xml.value('(./data[@name="writes"]/value)[1]', 'bigint') as writes,
 event_xml.value('(./action[@name="sql_text"]/value)[1]', 'varchar(4000)') as sql_text
FROM (SELECT CAST(event_data AS XML) xml_event_data 
  FROM sys.fn_xe_file_target_read_file('C:\КАК ХОЧУ\nuhbeb_0_133239478116000000.xel', NULL, NULL, NULL)) AS event_table
 CROSS APPLY xml_event_data.nodes('//event') n (event_xml);



 ------------------------------------------------------
 ------------------------------------------------------


 CREATE EVENT SESSION [XE session 01] ON SERVER 
ADD EVENT sqlserver.error_reported(
    ACTION(sqlos.cpu_id,sqlserver.database_id,sqlserver.database_name,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[database_id]>(4))),
ADD EVENT sqlserver.sql_batch_completed(
    WHERE ([sqlserver].[database_id]>(4))),
ADD EVENT sqlserver.sql_statement_completed(
    WHERE ([sqlserver].[database_id]>(4)))
ADD TARGET package0.event_file(SET filename=N'C:\Users\user\LAB_DB\nuhbeb-2.xel'),
ADD TARGET package0.ring_buffer
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=ON)
GO


 alter event session [XE session 01]
 on server
 add target package0.event_file(SET filename=N'C:\Users\user')

 declare @table table(module_guid nvarchar(100) not null,
 package_guid nvarchar(100) not null,
 object_name nvarchar(100) not null,
 event_data nvarchar(max),
 file_name nvarchar(100) not null,
 file_offset int not null,
 timestamp_utc datetime not null
 )

 insert into @table
 SELECT * FROM sys.fn_xe_file_target_read_file('C:\Users\user\LAB_DB\nuhbeb_0_133239478116000000.xel', NULL, NULL, NULL)
 


 USE master;  

GO  
SELECT OBJECT_ID(N'Результаты_сессии') AS 'Object ID';  
GO  




SELECT object_name, description
FROM sys.dm_xe_object_columns
WHERE name = 'object_id'



CREATE EVENT SESSION [audit_table_usage] ON SERVER
ADD EVENT sqlserver.lock_acquired (
    SET collect_database_name = (0)
        ,collect_resource_description = (1)
    ACTION(sqlserver.client_app_name, sqlserver.is_system, sqlserver.server_principal_name)
    WHERE (
        [package0].[equal_boolean]([sqlserver].[is_system], (0)) -- user SPID
        AND [package0].[equal_uint64]([resource_type], (5)) -- OBJECT
        AND [package0].[not_equal_uint64]([database_id], (32767))  -- resourcedb
        AND [package0].[greater_than_uint64]([database_id], (4)) -- user database
        AND [package0].[greater_than_equal_int64]([object_id], (245575913)) -- user object
        AND (
               [mode] = (1) -- SCH-S
            OR [mode] = (6) -- IS
            OR [mode] = (8) -- IX
            OR [mode] = (3) -- S
            OR [mode] = (5) -- X
        )
    )
)
WITH (
     MAX_MEMORY = 20480 KB
    ,EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS
    ,MAX_DISPATCH_LATENCY = 30 SECONDS
    ,MAX_EVENT_SIZE = 0 KB
    ,MEMORY_PARTITION_MODE = NONE
    ,TRACK_CAUSALITY = OFF
    ,STARTUP_STATE = OFF
);
GO