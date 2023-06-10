/********************************************************************************************

***  Blocking and deadlock monitor ***
------------------------------------------------

I have prepared this script to monitor blocking  sessions with sp_whoisactive,
So first you need tocreate sp_whoisactive stored procedure, 
please downad it from the link,

https://github.com/SqlAdmin/AwesomeSQLServer/blob/master/T-SQL%20Scripts/sp_whoisactive.sql

*******************************************************************************************/ 


-- To get overall info about current sessions

EXEC sp_whoisactive
---общая информация о текущих сеансах
---dd hh:mm:ss:mss - для активного запроса показывает время выполнения, для «спящей» сессии — время «сна»;
---session_id — айди сессии;
---sql_text — показывает текст выполняемого сейчас запроса, либо текст последнего выполненного запроса, если сессия спит;
----login_name - логин под которым был воспроизведен запрос
---wait_info —  выводится в формате (Ax: Bms/Cms/Dms)E.
------А — это количество ожидающих задач на ресурсе E. 
------B/C/D — это время ожидания в миллисекундах. 
------Если ожидает освобождения ресурса всего одна сессия, будет показано ее время ожидания, 
------если 2 сессии — их времена ожидания в формате B/C. 
------Если же ожидают 3 и более — мы увидим минимальное, 
------среднее и максимальное время ожидания на ЭТОМ ресурсе в формате B/C/D;
---CPU — для активного запроса — суммарное время Центарального Процессора, затраченное этим запросом, 
-------для спящей сессии — суммарное время ЦП за «всю жизнь» этой сессии;
----tempdb_allocations — количество операций записи в базе данных за время выполнения запроса; 
-------для спящей сессии — суммарное количество записей в TempDB за все время жизни сессии;
---tempdb_current — количество страниц в базе данных, выделенных для этого запроса; 
-------для спящей сессии — суммарное количество страниц в базе данных, выделенных за все время жизни сессии;
---blocking_session_id — если вдруг мы кем-то заблокированы, покажется айди (session_id) того, кем мы заблокированы;
---reads — количество логических чтений выполненных при выполнении этого запроса; 
-------для спящей сессии — количество прочитанных страниц за все время жизни этой сессии;
---writes — количество логических записей выполненных при выполнении этого запроса; 
-------для спящей сессии — количество записанных страниц за все время жизни этой сессии;
---physical_reads — количество физических чтений, выполненных при выполнении этого запроса; 
-------для спящей сессии — традиционно, суммарное количество физических чтений за все время жизни сессии;
---used_memory — количество восьмикилобайтовых страниц, использованных при выполнении этого запроса; 
-------для спящей сессии — сколько суммарно страниц памяти выделялось ей за все ее время жизни;
---status — статус сессии (выполняется, спит...);
---open_tran_count — показывает количество транзакций открытых этой сессией;
---percent_complete — показывает, если есть такая возможность, 
--------процесс выполнения операции (например, BACKUP, RESTORE), никогда не покажет на сколько процентов выполнен SELECT.

---------------------------------------
/*** 1. Monitor blocking session ***/
---------------------------------------

EXEC sp_WhoIsActive @find_block_leaders = 1,
                    @output_column_list = '[dd%][session_id][database_name][login_name] [sql_text][wait_info][blocking_session_id][blocked_session_count]',
                    @sort_order = '[start_time] ASC';

----Отслеживать сеанс блокировки
------dd hh:mm:ss:mss - для активного запроса показывает время выполнения, для спящей сессии — время «сна»;
------session_id — айди сессии;
------datadasename - название базы данных
----login_name - логин под которым был воспроизведен запрос
---sql_text — показывает текст выполняемого сейчас запроса, либо текст последнего выполненного запроса, если сессия спит;
---wait_info —  выводится в формате (Ax: Bms/Cms/Dms)E.
------А — это количество ожидающих задач на ресурсе E. 
------B/C/D — это время ожидания в миллисекундах. 
------Если ожидает освобождения ресурса всего одна сессия, будет показано ее время ожидания, 
------если 2 сессии — их времена ожидания в формате B/C. 
------Если же ожидают 3 и более — мы увидим минимальное, 
------среднее и максимальное время ожидания на ЭТОМ ресурсе в формате B/C/D;
---blocking_session_id — если вдруг мы кем-то заблокированы, покажется айди (session_id) того, кем мы заблокированы;
---blocked_session_count может помочь найти начало цепочки блокировок
---если [blocked_session_count] > 0, в то время как [blocking_session_id] = null, т. Е. если сеанс [X] не заблокирован другим сеансом, но он блокирует другие, это означает, что сеанс [X] является началом цепочки блокировок.



---------------------------------------
/*** 2. Monitor deadlocking session ***/
---------------------------------------

WITH [Blocking]
AS (SELECT
  w.[session_id],
  s.[original_login_name],
  s.[login_name],
  w.[wait_duration_ms],
  w.[wait_type],
  r.[status],
  r.[wait_resource],
  w.[resource_description],
  s.[program_name],
  w.[blocking_session_id],
  s.[host_name],
  r.[command],
  r.[percent_complete],
  r.[cpu_time],
  r.[total_elapsed_time],
  r.[reads],
  r.[writes],
  r.[logical_reads],
  r.[row_count],
  q.[text],
  q.[dbid],
  p.[query_plan],
  r.[plan_handle]
FROM [sys].[dm_os_waiting_tasks] w
INNER JOIN [sys].[dm_exec_sessions] s
  ON w.[session_id] = s.[session_id]
INNER JOIN [sys].[dm_exec_requests] r
  ON s.[session_id] = r.[session_id]
CROSS APPLY [sys].[dm_exec_sql_text](r.[plan_handle]) q
CROSS APPLY [sys].[dm_exec_query_plan](r.[plan_handle]) p
WHERE w.[session_id] > 50
AND w.[wait_type] NOT IN ('DBMIRROR_DBM_EVENT'
, 'ASYNC_NETWORK_IO'))
SELECT
  b.[session_id] AS [WaitingSessionID],
  b.[blocking_session_id] AS [BlockingSessionID],
  b.[login_name] AS [WaitingUserSessionLogin],
  s1.[login_name] AS [BlockingUserSessionLogin],
  b.[original_login_name] AS [WaitingUserConnectionLogin],
  s1.[original_login_name] AS [BlockingSessionConnectionLogin],
  b.[wait_duration_ms] AS [WaitDuration],
  b.[wait_type] AS [WaitType],
  t.[request_mode] AS [WaitRequestMode],
  UPPER(b.[status]) AS [WaitingProcessStatus],
  UPPER(s1.[status]) AS [BlockingSessionStatus],
  b.[wait_resource] AS [WaitResource],
  t.[resource_type] AS [WaitResourceType],
  t.[resource_database_id] AS [WaitResourceDatabaseID],
  DB_NAME(t.[resource_database_id]) AS [WaitResourceDatabaseName],
  b.[resource_description] AS [WaitResourceDescription],
  b.[program_name] AS [WaitingSessionProgramName],
  s1.[program_name] AS [BlockingSessionProgramName],
  b.[host_name] AS [WaitingHost],
  s1.[host_name] AS [BlockingHost],
  b.[command] AS [WaitingCommandType],
  b.[text] AS [WaitingCommandText],
  b.[row_count] AS [WaitingCommandRowCount],
  b.[percent_complete] AS [WaitingCommandPercentComplete],
  b.[cpu_time] AS [WaitingCommandCPUTime],
  b.[total_elapsed_time] AS [WaitingCommandTotalElapsedTime],
  b.[reads] AS [WaitingCommandReads],
  b.[writes] AS [WaitingCommandWrites],
  b.[logical_reads] AS [WaitingCommandLogicalReads],
  b.[query_plan] AS [WaitingCommandQueryPlan],
  b.[plan_handle] AS [WaitingCommandPlanHandle]
FROM [Blocking] b
INNER JOIN [sys].[dm_exec_sessions] s1
  ON b.[blocking_session_id] = s1.[session_id]
INNER JOIN [sys].[dm_tran_locks] t
  ON t.[request_session_id] = b.[session_id]
WHERE t.[request_status] = 'WAIT'
GO     

---Отслеживать сеанс взаимоблокировки
---WaitingSessionID – айди сеанса ожидания.
---BlockingSessionID – айди сеанса блокировки.
---WaitingSessionUserLogin – имя входа в сеанс пользователя, под которым в данный момент выполняется ожидающий сеанс.
---BlockingSessionUserLogin – имя входа в сеанс пользователя, под которым в данный момент выполняется сеанс блокировки.
---WaitingUserConnectionLogin – имя входа, которое пользователь использовал для создания сеанса ожидания.
---BlockingSessionConnectionLogin – имя входа, которое пользователь использовал для создания сеанса ожидания.
---WaitDuration – время ожидания процесса ожидания в миллисекундах.
---WaitType – Тип ожидания.
----WaitRequestMode – Режим запроса ожидания.
---WaitingProcessStatus – состояние ожидающего процесса.
---BlockingSessionStatus – статус процесса блокировки.
---WaitResource – имя ожидаемого запроса ресурса.
---WaitResourceType – тип ожидаемого запроса ресурса.
---WaitResourceDatabaseID – идентификатор базы данных, в которой существует запрошенный ресурс.
---WaitResourceDatabaseName – имя базы данных, в которой существует запрошенный ресурс.
---WaitResourceDescription – Подробное описание ожидающего ресурса.
---WaitingSessionProgramName – имя программы, которая инициировала сеанс ожидания.
---BlockingSessionProgramName – имя программы, которая инициировала сеанс блокировки.
---WaitingHost – название рабочей станции, специфичной для сеанса ожидания.
---BlockingHost – имя рабочей станции, специфичное для сеанса блокировки.
---WaitingCommandType – тип команды сеанса ожидания.
---WaitingCommandText – текст команды сеанса ожидания.
---WaitingCommandRowCount – Ожидаемое количество строк, возвращаемых ожидающим сеансом.
---WaitingCommandPercentComplete – Процент от ожидающего запроса клиента.
---WaitingCommandCPUTime – процессорное время, используемое сеансом ожидания.
---Ожидание командной строки завершилось заданным временем – Общее время, прошедшее в миллисекундах с момента поступления ожидающего запроса.
---Ожидающие командные потоки – количество операций чтения, выполняемых ожидающим запросом сеанса.
---Ожидающие командные записи – количество операций записи, выполняемых ожидающим запросом сеанса.
---Ожидающие командные логические чтения – количество логических операций чтения, выполняемых ожидающим запросом сеанса.
---WaitingCommandQueryPlan – План выполнения ожидающей команды.
---WaitingCommandPlanHandle – дескриптор планирования команды сеанса ожидания.
