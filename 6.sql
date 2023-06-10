--1--
Create Database EventTargetDB;

use EventTargetDB
Create table user_info(
id int identity(1,1) Primary Key,
data nvarchar(50) null)

Create table prod_info(
id int identity(1,1) Primary Key,
data nvarchar(50) null)

--2--
CREATE EVENT SESSION [ExEv666] ON SERVER 
--
ADD EVENT sqlserver.error_reported(
    ACTION(sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[database_name]=N'EventTargetDB' AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%user_info%') AND [sqlserver].[username]=N'sa')),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[database_name]=N'EventTargetDB' AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%user_info%') AND [sqlserver].[username]=N'sa'))
ADD TARGET package0.event_file(SET filename=N'C:\Users\Public\Report.xel',max_file_size=(2048),max_rollover_files=(0))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO

--3--
Insert into user_info
values
('dad');

select * from sys.server_event_sessions

SELECT * FROM sys.fn_xe_file_target_read_file('C:\Users\Public\Report_0_133305721642660000.xel', NULL, NULL, NULL)

SELECT CAST(event_data AS XML) AS EventData
FROM sys.fn_xe_file_target_read_file('C:\Users\Public\Report_0_133305721642660000.xel', NULL, NULL, NULL) 

SELECT AVG(event_xml.value('(./data[@name="duration"]/value)[1]', 'bigint')) as duration
FROM (SELECT CAST(event_data AS XML) xml_event_data 
  FROM sys.fn_xe_file_target_read_file('C:\Users\Public\Report_0_133305721642660000.xel', NULL, NULL, NULL)) AS event_table
 CROSS APPLY xml_event_data.nodes('//event') n (event_xml)

--4--
SELECT AVG(event_xml.value('(./data[@name="duration"]/value)[1]', 'bigint')) as duration
FROM (SELECT CAST(event_data AS XML) xml_event_data 
  FROM sys.fn_xe_file_target_read_file('C:\Users\Public\Report_0_133305721642660000.xel', NULL, NULL, NULL)) AS event_table
 CROSS APPLY xml_event_data.nodes('//event') n (event_xml)
WHERE event_xml.value('(./data[@name="database_name"]/value)[1]', 'nvarchar(50)') = 'EventTargetDB'

--5--
ALTER EVENT SESSION [ExEv666]
    ON SERVER
    STATE = START;   -- STOP;

alter event session [ExEv666]
	on server
	add target package0.event_file(SET filename=N'C:\Users\Public\6.xel')

--7--
/*Изучить инструменты SQL Profiler и Extended Events и сравнить их возможности и эффективность.*/	