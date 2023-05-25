SELECT total_physical_memory_kb / 1024 AS

[Total Physical Memory],

available_physical_memory_kb / 1024 AS

[Available Physical Memory],

total_page_file_kb / 1024 AS

[Total Page File (MB)],

available_page_file_kb / 1024 AS

[Available Page File (MB)],

100 - ( 100 * Cast(available_physical_memory_kb AS DECIMAL(18, 3)) / Cast

(

total_physical_memory_kb AS DECIMAL(18, 3)) ) AS

'Percentage Used',

system_memory_state_desc AS

[Memory State]

FROM sys.dm_os_sys_memory;


--Загрузка процессора в SQL Server

DECLARE @ts BIGINT;

DECLARE @lastNmin TINYINT;

SET @lastNmin = 30; // нагрузка за прошедшие n минут

SELECT @ts = (SELECT cpu_ticks / ( cpu_ticks / ms_ticks )

FROM sys.dm_os_sys_info);

SELECT TOP(@lastNmin) Dateadd(ms, -1 * ( @ts - [timestamp] ), Getdate())AS

[EventTime],

sqlprocessutilization AS

[SQL Server Utilization],

100 - systemidle - sqlprocessutilization AS

[Other Process CPU_Utilization],

systemidle AS

[System Idle]

FROM (SELECT

record.value('(./Record/@id)[1]', 'int') AS record_id,

record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS [SystemIdle],

record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int')AS [SQLProcessUtilization],

[timestamp]

FROM (SELECT[timestamp],

CONVERT(XML, record) AS [record]

FROM sys.dm_os_ring_buffers

WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'

AND record LIKE'%%')AS x)AS y

ORDER BY record_id DESC;
